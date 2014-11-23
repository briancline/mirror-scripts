#!/usr/bin/env python
from __future__ import print_function
import os
import requests


# TODO(bc): provide these via config and/or argparse
MIRROR_PATH = '/mnt/mirrors.os02/ubuntu-cloud'
RELEASE_LIST = ['precise',
                'trusty',
                'utopic']
ARCH_LIST = ['amd64']
LABEL_LIST = ['release']
ITEM_LIST = ['disk1.img',
             'disk.img']

UPSTREAM_BASE = 'http://cloud-images.ubuntu.com'
UPSTREAM_FEED = 'releases/streams/v1/com.ubuntu.cloud:released:download.json'


def download_file(url, local_path, sum=None):
    parent_dir = os.path.dirname(local_path)
    try:
        os.makedirs(parent_dir)
    except Exception:
        pass

    resp = requests.get(url, stream=True)

    with open(local_path, 'w') as ff:
        for chunk in resp.iter_content(chunk_size=4096):
            if not chunk:
                continue

            ff.write(chunk)
            ff.flush()

    return True


def download_items(items):
    items = sorted(items, lambda x, y: cmp(x['path'], y['path']))

    for item in items:
        local_path = '%s/%s' % (MIRROR_PATH, item['path'])
        url = '%s/%s' % (UPSTREAM_BASE, item['path'])

        if os.path.exists(local_path):
            continue

        print(local_path)
        download_file(url, local_path)


def update_links(links):
    for link_name, link_target in links.iteritems():
        link_path = '%s/server/releases/%s' % (MIRROR_PATH, link_name)
        link_target = '%s/server/releases/%s' % (MIRROR_PATH, link_target)

        if os.path.exists(link_path) and os.path.islink(link_path):
            existing_target = os.path.realpath(link_path)

            if existing_target != link_target:
                print('Updating link %s -> %s' % (link_path, link_target))
                os.unlink(existing_target)

        try:
            os.symlink(link_target, link_path)
        except Exception:
            pass


def mirror():
    mirror_items = []
    local_links = {}

    resp = requests.get('%s/%s' % (UPSTREAM_BASE, UPSTREAM_FEED))
    for product_key, product in resp.json().get('products').iteritems():
        if product['release'] not in RELEASE_LIST:
            continue
        if product['arch'] not in ARCH_LIST:
            continue

        versions = {k: v for k, v in product['versions'].iteritems()
                    if v['label'] in LABEL_LIST}

        latest_ver = sorted(product['versions'])[-1]
        release_current = '%s/current' % product['release']
        current_target = '%s/release-%s' % (product['release'], latest_ver)
        local_links.update({product['version']: product['release'],
                            release_current: current_target})

        for version_key, version in versions.iteritems():
            items = [v for k, v in version['items'].iteritems()
                     if k in ITEM_LIST]
            mirror_items += items

    download_items(mirror_items)
    update_links(local_links)


if __name__ == '__main__':
    mirror()
