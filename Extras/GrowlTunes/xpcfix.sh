#!/bin/bash

BASEID="com.company.application"
MYID="${MYID:=com.growl.growltunes}"
APPNAME="${APPNAME:=growltunes}"
GNTPENTITLEMENTS="${GNTPENTITLEMENTS:=${PROJECT_DIR}/../../XPC/GNTP Client/GNTPClientService.entitlements}"
MYENTITLEMENTS="${MYENTITLEMENTS:=${PROJECT_DIR}/${APPNAME}/${APPNAME}.entitlements}"
APPRESIGN="no"


pushd "${BUILT_PRODUCTS_DIR}" > /dev/null
pushd "${CONTENTS_FOLDER_PATH}" > /dev/null
pushd "XPCServices" > /dev/null

if [[ -d "${MYID}.GNTPClientService.xpc" ]]; then
    echo "deleting previous app specific GNTPClientService"
    echo "rm -rf \"${MYID}.GNTPClientService.xpc\""
    rm -rf "${MYID}.GNTPClientService.xpc"
fi

if [[ -d "${BASEID}.GNTPClientService.xpc" ]]; then
    
    echo "generic identifier GNTPClientService found, fixing"
    
    AUTHORITY="$(codesign -dvv "${BASEID}.GNTPClientService.xpc" 2>&1 | grep ^Authority | awk -F= '{print $2}')"
    IDENTIFIER="$(codesign -dvv "${BASEID}.GNTPClientService.xpc" 2>&1 | grep ^Identifier | awk -F= '{print $2}')"
    UIDENTIFIER="${IDENTIFIER#$BASEID.}"
    NEWIDENTIFIER="${MYID}.${UIDENTIFIER}"
    
    echo "mv ${BASEID}.GNTPClientService.xpc ${MYID}.GNTPClientService.xpc"
    mv "${BASEID}.GNTPClientService.xpc" "${MYID}.GNTPClientService.xpc"
    
    pushd "${MYID}.GNTPClientService.xpc/Contents" > /dev/null
    echo "mv MacOS/${BASEID}.GNTPClientService MacOS/${MYID}.GNTPClientService"
    mv "MacOS/${BASEID}.GNTPClientService" "MacOS/${MYID}.GNTPClientService"
    
    echo "performing sed -e 's|${BASEID}|${MYID}|g' on Info.plist"
    cat Info.plist | sed -e "s|${BASEID}|${MYID}|g" > out.plist
    cat out.plist > Info.plist
    rm out.plist
    
    popd > /dev/null # "${MYID}.GNTPClientService.xpc/Contents"
    
    echo "resigning app specific GNTPClientService"
    echo "codesign -f -s \"${AUTHORITY}\" -i \"${NEWIDENTIFIER}\" --entitlements \"${GNTPENTITLEMENTS}\" --verbose=5 ./\"${MYID}.GNTPClientService.xpc\""
    codesign -f -s "${AUTHORITY}" -i "${NEWIDENTIFIER}" --entitlements "${GNTPENTITLEMENTS}" --verbose=5 ./"${MYID}.GNTPClientService.xpc"
    
    APPRESIGN="yes"
    
else
    echo "generic GNTPClientService not found"
    exit 1
fi

popd > /dev/null # XPCServices
popd > /dev/null # CONTENTS_FOLDER_PATH

if [[ "${APPRESIGN}" == "yes" ]]; then
    echo "resigning application to account for resigned GNTPClientService"
    echo "codesign -f -s \"${AUTHORITY}\" --entitlements \"${MYENTITLEMENTS}\" --preserve-metadata=identifier --verbose=5 ./\"${APPNAME}.app\""
    codesign -f -s "${AUTHORITY}" --entitlements "${MYENTITLEMENTS}" --preserve-metadata=identifier --verbose=5 ./"${APPNAME}.app"
fi

popd > /dev/null # BUILT_PRODUCTS_DIR
