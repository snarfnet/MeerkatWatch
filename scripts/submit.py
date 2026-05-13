#!/usr/bin/env python3
import jwt, time, requests, sys, os

KEY_ID  = 'WDXGY9WX55'
ISSUER  = '2be0734f-943a-4d61-9dc9-5d9045c46fec'
P8_PATH = os.path.expanduser('~/.appstoreconnect/private_keys/AuthKey_WDXGY9WX55.p8')
APP_ID  = '6768575235'

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

r = api('GET', f'/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=1')
versions = r.json().get('data', [])
if not versions:
    print('No version found'); sys.exit(0)

VERSION_ID = versions[0]['id']
state      = versions[0]['attributes']['appStoreState']
print(f'Version: {VERSION_ID}  state={state}')

if state in ('WAITING_FOR_REVIEW', 'IN_REVIEW', 'READY_FOR_SALE'):
    print('Already submitted or on sale'); sys.exit(0)

review_notes = (
    'Guideline 5.1.2(i)対応: 初回起動時にApp Tracking Transparencyの許可ダイアログを表示します。'
    '場所: アプリ起動直後、広告SDKを開始する前です。'
    'ユーザーが許可しない場合も、集中タイマー、巣穴、仲間機能はそのまま利用できます。'
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
                 'relationships': {'build': {'data': {'type': 'builds', 'id': build_id}}}}
    })
    api('PATCH', f'/builds/{build_id}', {
        'data': {'type': 'builds', 'id': build_id,
                 'attributes': {'usesNonExemptEncryption': False}}
    })

rs = api('POST', '/reviewSubmissions', {
    'data': {'type': 'reviewSubmissions',
             'attributes': {'platform': 'IOS'},
             'relationships': {'app': {'data': {'type': 'apps', 'id': APP_ID}}}}
})
rs_id = rs.json().get('data', {}).get('id')
if not rs_id:
    existing = api('GET', f'/apps/{APP_ID}/reviewSubmissions?filter[platform]=IOS&filter[state]=WAITING_FOR_REVIEW,UNRESOLVED_ISSUES')
    subs = existing.json().get('data', [])
    if subs:
        rs_id = subs[0]['id']
    else:
        print('Could not create/find reviewSubmission'); sys.exit(1)

api('POST', '/reviewSubmissionItems', {
    'data': {'type': 'reviewSubmissionItems',
             'relationships': {
                 'reviewSubmission': {'data': {'type': 'reviewSubmissions', 'id': rs_id}},
                 'appStoreVersion':  {'data': {'type': 'appStoreVersions',  'id': VERSION_ID}}
             }}
})

submit = api('PATCH', f'/reviewSubmissions/{rs_id}', {
    'data': {'type': 'reviewSubmissions', 'id': rs_id,
             'attributes': {'submitted': True}}
})
if submit.status_code == 200:
    print('=== SUBMITTED FOR REVIEW ===')
