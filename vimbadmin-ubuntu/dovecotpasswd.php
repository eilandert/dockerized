#!/usr/bin/php
<?php

  $newpass = $argv[1];

  // Generate random salt
  $salt = substr(bin2hex(openssl_random_pseudo_bytes(16)),0,16);

  // $6$ specifies SHA512
  $hashed = crypt($newpass, sprintf('$6$%s$', $salt));

  echo "{SHA512-CRYPT}$hashed\n"

?>

