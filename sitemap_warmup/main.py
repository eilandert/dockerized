#!/usr/bin/env python3
import os
import sys
import datetime
import argparse
import functools
import asyncio
import aiohttp
import requests
import pandas as pd
from lxml import etree, html
from tabulate import tabulate
from urllib.parse import urlparse

parser = argparse.ArgumentParser(description='Asynchronous CDN Cache Warmer')
parser.add_argument('-s', '--site', action="append", dest='sites', default=None)
parser.add_argument('-d', '--depth', action="store", dest='depth', default=None)
parser.add_argument('-c', '--concurrency', action="store", dest='concurrency', default=1)
parser.add_argument('-o', '--output',  action="store_true", default=None)
parser.add_argument('-q', '--quiet', action="store_true", help="Only print 40x, 50x or 200 with noindex")
args = parser.parse_args()
concurrency = args.concurrency
depth = args.depth
sites = args.sites
quiet = args.quiet
output = args.output


# Colorize #
red = '\033[0;31m'
green = '\033[0;32m'
no_color = '\033[0m'

tasks = []
tab_headers = ['URL', 'Response code', 'Time (ms)', 'Meta Robots', 'Cache Control']
results = pd.DataFrame(columns=['domain', 'http_code', 'time', 'robots_status', 'cache_control'])
time_array = []
dot = 0
dot_total = 0
failed_links = 0
success_links = 0
domain = ''
headers = {'User-Agent': 'Googlebot/2.1 (+http://www.googlebot.com/bot.html)'}


def get_links(mage_links):
    r = requests.get(mage_links)
    if "200" not in str(r):
        sys.exit(red + "Sitemap fetch failed for %s with %s. Exiting..." % (mage_links, r) + no_color)
    root = etree.fromstring(r.content)
    print("URLs on sitemap found: %s" % str((len(root))))
    links = []
    for sitemap in root:
        prefix, tag = sitemap.tag.split("}")
        children = sitemap.getchildren()
        if tag == 'sitemap':
            print("Sitemap Index found %s" % children[0].text)
            sites.append(children[0].text)
        else:
            links.append(children[0].text)
    return links


async def bound_warms(sem, url):
    async with sem:
        await warm_it(url)


async def warm_it(url):

    connection_started_time = None
    connection_made_time = None

    class TimedResponseHandler(aiohttp.client_proto.ResponseHandler):
        def connection_made(self, transport):
            nonlocal connection_made_time
            connection_made_time = datetime.datetime.now()
            return super().connection_made(transport)

    class TimedTCPConnector(aiohttp.TCPConnector):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            self._factory = functools.partial(TimedResponseHandler, loop=loop)

        async def _create_connection(self, req, traces, timeout):
            nonlocal connection_started_time
            connection_started_time = datetime.datetime.now()
            return await super()._create_connection(req, traces, timeout)

    async with aiohttp.ClientSession(connector=TimedTCPConnector(loop=loop), headers=headers) as session:
        async with session.get(url) as response:
            global dot, dot_total, results
            time_delta = connection_made_time - connection_started_time
            time_taken = "%s.%s" % (time_delta.seconds, time_delta.microseconds)

            robots_status = ""
            cache_control = ""

            if response.status != 200:
                response_output = red + str(response.status) + no_color
            else:
                response_output = green + str(response.status) + no_color
                time_array.append(time_delta)
                doc = html.fromstring(await response.text())
                robots = doc.xpath("//meta[@name='robots']/@content")

                if len(robots) > 0:
                    robots_status = 'NA'
                    if 'noindex' in robots[0]:
                        robots_status = 'NI'
                        response_output = red + str(response.status) + no_color
                    elif 'index' in robots[0]:
                        robots_status = 'I'
                    elif 'index,follow' in robots[0]:
                        robots_status = 'IF'
                else:
                    robots_status = 'NA'

                if 'Cache-Control' in response.headers:
                    current_control = response.headers['Cache-Control'].split(', ')
                    cache_control = current_control[0].replace('max-age=', '')

            if (quiet is False) or ((quiet is True) and (response.status != 200)):
                res = {'domain': url.replace(domain, ''),
                       'http_code': response_output,
                       'time': time_taken[:5],
                       'robots_status': robots_status,
                       'cache_control': cache_control}
                results = results.append(res, ignore_index=True)

            if quiet is False:
                dot += 1
                if dot == 100:
                    dor = ". %i\n" % dot_total
                    dot = 0
                    dot_total += 100
                else:
                    dor = '.'

                print(dor, end='', flush=True)

            del doc, robots, response


def write_list_to_csv(current_sites, headers, results):
    a = urlparse(current_sites)
    url_file = os.path.basename(a.path)
    filename = url_file.split('.')

    results.to_csv('/tmp/%s.csv' % filename[0], encoding='utf-8', index=False)


def main():

    global success_links, failed_links, time_array, results, domain, tab_headers

    if concurrency is None:
        print("The concurrency limit isn't specified. Setting limit to 150")
    else:
        print("Setting concurrency limit to %s Quiet: %s Output: %s" % (concurrency, quiet, output))
        print("\n")

    iteration = 0
    while sites:
        current_sites = sites.pop(0)
        domain = urlparse(current_sites)
        domain = domain.scheme+'://'+domain.netloc

        print("SITEMAP: %s" % current_sites)

        mage_links = get_links(str(current_sites))

        if len(mage_links) > 0:
            for i in mage_links:
                task = asyncio.ensure_future(bound_warms(sem, i))
                tasks.append(task)
            loop.run_until_complete(asyncio.wait(tasks))

            if results is not None and isinstance(results, pd.DataFrame) and not results.empty:
                for index, row in results.iterrows():
                    if "200" in row["http_code"]:
                        success_links += 1
                    else:
                        failed_links += 1

            avg_time = str((sum([x.total_seconds() for x in time_array]))/len(time_array))

            print("\n")
            print("Meta Robots: I = index, IF=index/follow, F=noindex, NA = Not Found")
            print(tabulate(results, showindex=True,
                           headers=tab_headers))
            print(tabulate([[str(failed_links), str(success_links), avg_time]],
                           headers=['Failed', 'Successful', 'Average Time']))

            if output is True:
                write_list_to_csv(current_sites, tab_headers, results)

            iteration += 1
            if (depth is not False) and iteration == depth:
                print("Depth level of %i reach" % iteration)
                exit()

            del mage_links
            results = results.iloc[0:0]

        print("END INTERATION %i \n" % iteration)


if __name__ == "__main__":

    sem = asyncio.Semaphore(int(concurrency))
    loop = asyncio.get_event_loop()

    # execute only if run as a script
    main()

'''
            if results is not None:
'''