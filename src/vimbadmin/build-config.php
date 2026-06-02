<?php
/**
 * Build the full application.ini from a small local.ini overlay.
 *
 *   php build-config.php <template.ini> <local.ini> <out application.ini>
 *
 * The template is the shipped full ViMbAdmin config (all framework plumbing).
 * local.ini holds only the ~15 deployment knobs (short keys). We map those to
 * the real ZF1 keys and append them as a [docker : production] overlay, which
 * is the active env and loaded last, so it wins. securitysalt is generated
 * once and written back into local.ini so it persists across restarts.
 *
 * Unknown/blank local keys are ignored. The operator never edits the big file.
 */

list(, $tplPath, $localPath, $outPath) = $argv + [null, null, null, null];
if (!$tplPath || !$localPath || !$outPath) {
    fwrite(STDERR, "usage: build-config.php <template> <local.ini> <out>\n");
    exit(2);
}

$local = parse_ini_file($localPath, false, INI_SCANNER_RAW);
if ($local === false) { fwrite(STDERR, "build-config: cannot parse $localPath\n"); exit(1); }

// --- ensure a persistent securitysalt (generate once, store in local.ini) ---
$salt = isset($local['securitysalt']) ? trim($local['securitysalt']) : '';
if (!preg_match('/^[0-9a-f]{32,}$/', $salt)) {
    $salt = bin2hex(random_bytes(32));
    file_put_contents($localPath, "\nsecuritysalt = \"$salt\"\n", FILE_APPEND);
    $local['securitysalt'] = $salt;
}

// --- map short local keys -> ZF1 application.ini keys ------------------------
$map = [
    'db.host'           => ['resources.doctrine2.connection.options.host'],
    'db.name'           => ['resources.doctrine2.connection.options.dbname'],
    'db.user'           => ['resources.doctrine2.connection.options.user'],
    'db.password'       => ['resources.doctrine2.connection.options.password'],
    'mailbox.maildir'   => ['defaults.mailbox.maildir'],
    'mailbox.homedir'   => ['defaults.mailbox.homedir'],
    'mailbox.uid'       => ['defaults.mailbox.uid'],
    'mailbox.gid'       => ['defaults.mailbox.gid'],
    'mailbox.scheme'    => ['defaults.mailbox.password_scheme'],
    'admin.email'       => ['identity.email', 'server.email.address'],
    'site.name'         => ['identity.sitename', 'identity.orgname'],
    'site.url'          => ['identity.siteurl'],
    'base_path'         => ['resources.frontController.baseUrl'],
    'trustedproxy.mode' => ['trustedproxy.mode'],
    'mcp.enabled'       => ['mcp.enabled'],
    'securitysalt'      => ['securitysalt'],
];

$overlay = [];
foreach ($map as $short => $targets) {
    if (!array_key_exists($short, $local) || trim((string)$local[$short]) === '') continue;
    $val = trim((string)$local[$short]);
    foreach ($targets as $zf1) $overlay[$zf1] = $val;
}
// Always force the cache backend the image ships (APCu).
$overlay['resources.doctrine2cache.type'] = 'ApcuCache';

// --- write: full template, then our [docker : production] overlay -----------
$tpl = file_get_contents($tplPath);
if ($tpl === false) { fwrite(STDERR, "build-config: cannot read $tplPath\n"); exit(1); }

// Drop any pre-existing [docker : production] section from the template so we
// own it cleanly (idempotent regeneration).
$tpl = preg_replace('/\n\[docker : production\].*$/s', "\n", $tpl);

$out = rtrim($tpl, "\n") . "\n\n[docker : production]\n";
$out .= ";; --- generated from local.ini; do not edit (edit local.ini) ---\n";
$out .= "resources.smarty.skin = \"dark\"\n";
foreach ($overlay as $k => $v) {
    $q = is_numeric($v) ? $v : '"' . str_replace('"', '\"', $v) . '"';
    $out .= "$k = $q\n";
}

file_put_contents($outPath, $out);

// validate
if (parse_ini_file($outPath, true) === false) {
    fwrite(STDERR, "build-config: generated application.ini failed to parse\n");
    exit(1);
}
echo "[VIMBADMIN] application.ini generated from local.ini (" . count($overlay) . " overrides)\n";
