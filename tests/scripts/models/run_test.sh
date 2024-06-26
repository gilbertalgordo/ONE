#!/usr/bin/env bash
#
# Copyright (c) 2018 Samsung Electronics Co., Ltd. All Rights Reserved
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


MY_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NNFW_HOME="$(dirname $(dirname $(dirname ${MY_PATH})))"
CACHE_ROOT_PATH=$MY_PATH/"cache"
TEST_ROOT_PATH=$MY_PATH/"tflite"
REPORT_DIR="report"

RUN_DISABLED="true"

function command_exists() {
	command -v "$@" > /dev/null 2>&1
}

function Usage()
{
    echo "Usage: ${BASH_SOURCE[0]} [OPTIONS] {tests to test or empty for all of tests}"
    echo "(Ex) : ${BASH_SOURCE[0]} --driverbin=Product/out/bin/onert_run --reportdir=report --tapname=verification.tap avgpool1 avgpool2"
    echo ""
    echo "--driverbin           : Runner for runnning model tests"
    echo "--reportdir           : (default=$REPORT_DIR) Directory to place tap files"
    echo "--tapname             : (default=$TAP_NAME) File name to be written for tap"
    echo "--configdir           : (default=$TEST_ROOT_PATH) Config directory to download and test model"
    echo "--cachedir            : (default=$CACHE_ROOT_PATH) Directory to download model"
    echo ""
}

DRIVER_BIN="$NNFW_HOME/Product/out/bin/onert_run"
TAP_NAME="framework_test.tap"
TEST_LIST=()

# Support environment variable setting for mirror server
FIXED_MODELFILE_SERVER="${MODELFILE_SERVER:-}"

for i in "$@"
do
    case $i in
        -h|--help|help)
            Usage
            exit 1
            ;;
        --driverbin=*)
            DRIVER_BIN=${i#*=}
            ;;
        --reportdir=*)
            REPORT_DIR=${i#*=}
            ;;
        --tapname=*)
            TAP_NAME=${i#*=}
            ;;
        --configdir=*)
            TEST_ROOT_PATH=${i#*=}
            ;;
        --cachedir=*)
            CACHE_ROOT_PATH=${i#*=}
            ;;
        *)
            TEST_LIST+=( $i )
            ;;
    esac
    shift
done

if [[ ${#TEST_LIST[@]} -eq 0 ]]; then
    RUN_DISABLED="false"
fi

if [ ! -d "$TEST_ROOT_PATH" ]; then
    echo "Cannot find config directory for test: please set proper configdir"
    exit 1
fi

# Check test driver setting
if ! command_exists $DRIVER_BIN ; then
    echo "Cannot find test driver" $DRIVER_BIN ": please set proper DRIVER_BIN"
    exit 1
fi

run_tests()
{
    echo "1..$#" > $REPORT_DIR/$TAP_NAME
    SELECTED_TESTS=$@

    echo ""
    echo "Running tests:"
    echo "======================"
    for TEST_NAME in $SELECTED_TESTS; do
        echo $TEST_NAME
    done
    echo "======================"

    TOTAL_RESULT=0  # 0(normal) or 1(abnormal)
    i=0
    for TEST_NAME in $SELECTED_TESTS; do
        # Test configure initialization
        ((i++))
        STATUS="enabled"
        MODELFILE_URL_BASE=""
        MODELFILE_NAME=""
        source $TEST_ROOT_PATH/$TEST_NAME/config.sh

        LOWER_STATUS="$(echo $STATUS | awk '{print tolower($0)}')"
        if [ "$LOWER_STATUS" == "disabled" ] && [ "$RUN_DISABLED" == "false" ]; then
            echo ""
            echo "Skip $TEST_NAME"
            echo "======================"
            echo "ok $i # skip $TEST_NAME" >> $REPORT_DIR/$TAP_NAME
            continue
        fi

        MODELFILE=$CACHE_ROOT_PATH/$MODELFILE_NAME

        # Find model file for downloaded by zip
        if [ "${MODELFILE_NAME##*.}" = "zip" ]; then
            pushd $CACHE_ROOT_PATH
            MODELFILE=$CACHE_ROOT_PATH/$(ls ${MODELFILE_NAME%.zip}/*.tflite)
            popd
        fi

        echo ""
        echo "Run $TEST_NAME"
        echo "======================"

        # Run driver to test framework
        $DRIVER_BIN $MODELFILE

        if [[ $? -eq 0 ]]; then
            echo "ok $i - $TEST_NAME" >> $REPORT_DIR/$TAP_NAME
        else
            echo "not ok $i - $TEST_NAME" >> $REPORT_DIR/$TAP_NAME
            TOTAL_RESULT=1
        fi
    done
    return $TOTAL_RESULT
}

find_tests()
{
    local TEST_DIRS="$@"
    local TESTS_TO_RUN=""

    if [[ $# -eq 0 ]]; then
        TEST_DIRS="."
    fi

    shift $#

    pushd $TEST_ROOT_PATH > /dev/null
    for DIR in $TEST_DIRS; do
        if [ -d "$DIR" ]; then
            TESTS_FOUND=$(find "$DIR" -type f -name 'config.sh' -exec dirname {} \;| sed 's|^./||' | sort)
            TESTS_TO_RUN="$TESTS_TO_RUN $TESTS_FOUND"
        else
            echo "Test $DIR was not found. This test is not added." 1>&2
        fi
    done
    popd > /dev/null

    echo $TESTS_TO_RUN
}

mkdir -p $REPORT_DIR
TESTS_TO_RUN=$(find_tests ${TEST_LIST[@]})
run_tests $TESTS_TO_RUN

exit $?
