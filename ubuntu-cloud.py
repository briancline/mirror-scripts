#!/usr/bin/env python
from __future__ import print_function
import os
import requests


# TODO(bc): provide these via config and/or argparse
MIRROR_PATH = '/mnt/mirrors.os02/ubuntu-cloud'
RELEASE_LIST = ['trusty',
                'utopic']
ARCH_LIST = ['amd64']
LABEL_LIST = ['release']
ITEM_LIST = ['disk1.img']

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


def mirror():
    download_items = []

    resp = requests.get('%s/%s' % (UPSTREAM_BASE, UPSTREAM_FEED))
    for product_key, product in resp.json().get('products').iteritems():
        if product['release'] not in RELEASE_LIST:
            continue
        if product['arch'] not in ARCH_LIST:
            continue

        for version_key, version in product['versions'].iteritems():
            if version['label'] not in LABEL_LIST:
                continue

            for item_type, item in version['items'].iteritems():
                if item_type not in ITEM_LIST:
                    continue

                download_items.append(item)

    download_items = sorted(download_items,
                            lambda x, y: cmp(y['path'], x['path']))

    for ii in download_items:
        local_path = '%s/%s' % (MIRROR_PATH, ii['path'])
        url = '%s/%s' % (UPSTREAM_BASE, ii['path'])

        print(local_path)

        if os.path.exists(local_path):
            continue

        download_file(url, local_path)


if __name__ == '__main__':
    mirror()
