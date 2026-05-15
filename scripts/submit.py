#!/usr/bin/env python3
import jwt, time, requests, sys, os

KEY_ID  = 'WDXGY9WX55'
ISSUER  = '2be0734f-943a-4d61-9dc9-5d9045c46fec'
P8_PATH = os.path.expanduser('~/.appstoreconnect/private_keys/AuthKey_WDXGY9WX55.p8')
APP_ID  = '6768575235'
APP_VERSION = os.environ.get('APP_VERSION', '1.1')

p8 = open(P8_PATH).read()

def make_token():
    return jwt.encode(
        {'iss': ISSUER, 'iat': int(time.time()), 'exp': int(time.time()) + 1200,
         'aud': 'appstoreconnect-v1'},
        p8, algorithm='ES256', headers={'kid': KEY_ID}
    )

def api(method, path, payload=None):
    h = {'Authorization': f'Bearer {make_token()}', 'Content-Type': 'application/json'}
    r = requests.request(method, f'https://api.appstoreconnect.apple.com/v1{path}',
                         headers=h, json=payload)
    print(method, path.split('?')[0][-60:], r.status_code)
    if r.status_code >= 400:
        print('  ERR:', r.text[:300])
    return r

def cancel_blocking_submissions():
    canceled = False
    for state_filter in ('UNRESOLVED_ISSUES', 'READY_FOR_REVIEW', 'WAITING_FOR_REVIEW'):
        r = api('GET', f'/apps/{APP_ID}/reviewSubmissions?filter[platform]=IOS&filter[state]={state_filter}&limit=20')
        if r.status_code >= 400:
            continue
        for sub in r.json().get('data', []):
            sid = sub['id']
            state = sub.get('attributes', {}).get('state', state_filter)
            cr = api('PATCH', f'/reviewSubmissions/{sid}', {
                'data': {'type': 'reviewSubmissions', 'id': sid,
                         'attributes': {'canceled': True}}
            })
            print(f'Cancel reviewSubmission {sid} state={state}: {cr.status_code}')
            if cr.status_code in (200, 204, 409):
                canceled = True
    return canceled

def find_or_create_version():
    r = api('GET', f'/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&filter[versionString]={APP_VERSION}&limit=1')
    versions = r.json().get('data', [])
    if versions:
        return versions[0]

    created = api('POST', '/appStoreVersions', {
        'data': {
            'type': 'appStoreVersions',
            'attributes': {
                'platform': 'IOS',
                'versionString': APP_VERSION,
                'releaseType': 'AFTER_APPROVAL'
            },
            'relationships': {
                'app': {'data': {'type': 'apps', 'id': APP_ID}}
            }
        }
    })
    if created.status_code != 201:
        print(f'Could not create App Store version {APP_VERSION}')
        sys.exit(1)
    return created.json()['data']

version = find_or_create_version()

VERSION_ID = version['id']
state      = version['attributes']['appStoreState']
print(f'Version {APP_VERSION}: {VERSION_ID}  state={state}')

if state in ('WAITING_FOR_REVIEW', 'IN_REVIEW', 'READY_FOR_SALE'):
    print('Already submitted or on sale'); sys.exit(0)

review_notes = (
    'Guideline 2.1 response: This build shows a launch privacy screen first, then displays the '
    'App Tracking Transparency system permission request before Google Mobile Ads is started '
    'and before any ad banner is loaded. After the user responds to the ATT dialog, the app '
    'opens the main meerkat timer flow. If the user does not allow tracking, all app features '
    'remain available.'
)

details = api('GET', f'/appStoreVersions/{VERSION_ID}/appStoreReviewDetail')
detail_id = details.json().get('data', {}).get('id') if details.status_code == 200 else None
if detail_id:
    api('PATCH', f'/appStoreReviewDetails/{detail_id}', {
        'data': {'type': 'appStoreReviewDetails', 'id': detail_id,
                 'attributes': {'notes': review_notes}}
    })
else:
    print('Review detail not found; please add review notes in App Store Connect if required.')

build_num = sys.argv[1] if len(sys.argv) > 1 else None
if build_num:
    print(f'Waiting for build {build_num} to be VALID...')
    build_id = None
    for i in range(120):
        r2 = api('GET', f'/builds?filter[app]={APP_ID}&filter[version]={build_num}&filter[processingState]=VALID')
        builds = r2.json().get('data', [])
        if builds:
            build_id = builds[0]['id']
            print(f'Build ready: {build_id}')
            break
        print(f'  attempt {i+1}/120, waiting 30s...')
        time.sleep(30)
    else:
        print('Build not ready after 60 min'); sys.exit(1)

    api('PATCH', f'/appStoreVersions/{VERSION_ID}', {
        'data': {'type': 'appStoreVersions', 'id': VERSION_ID,
                 'attributes': {'usesIdfa': True},
                 'relationships': {'build': {'data': {'type': 'builds', 'id': build_id}}}}
    })
    api('PATCH', f'/builds/{build_id}', {
        'data': {'type': 'builds', 'id': build_id,
                 'attributes': {'usesNonExemptEncryption': False}}
    })

if cancel_blocking_submissions():
    print('Waiting for canceled review submissions to clear...')
    time.sleep(30)
    if build_num and build_id:
        api('PATCH', f'/appStoreVersions/{VERSION_ID}', {
            'data': {'type': 'appStoreVersions', 'id': VERSION_ID,
                     'attributes': {'usesIdfa': True},
                     'relationships': {'build': {'data': {'type': 'builds', 'id': build_id}}}}
        })

rs_id = None
for attempt in range(5):
    rs = api('POST', '/reviewSubmissions', {
        'data': {'type': 'reviewSubmissions',
                 'attributes': {'platform': 'IOS'},
                 'relationships': {'app': {'data': {'type': 'apps', 'id': APP_ID}}}}
    })
    if rs.status_code == 201:
        rs_id = rs.json().get('data', {}).get('id')
        print(f'ReviewSubmission created: {rs_id}')
        break
    print(f'Create reviewSubmission attempt {attempt + 1}/5 failed: {rs.status_code} {rs.text[:300]}')
    if attempt < 4:
        time.sleep(15)

if not rs_id:
    print('Could not create reviewSubmission'); sys.exit(1)

item = api('POST', '/reviewSubmissionItems', {
    'data': {'type': 'reviewSubmissionItems',
             'relationships': {
                 'reviewSubmission': {'data': {'type': 'reviewSubmissions', 'id': rs_id}},
                 'appStoreVersion':  {'data': {'type': 'appStoreVersions',  'id': VERSION_ID}}
             }}
})
if item.status_code >= 400:
    sys.exit(1)

submit = api('PATCH', f'/reviewSubmissions/{rs_id}', {
    'data': {'type': 'reviewSubmissions', 'id': rs_id,
             'attributes': {'submitted': True}}
})
if submit.status_code == 200:
    print('=== SUBMITTED FOR REVIEW ===')
else:
    sys.exit(1)
