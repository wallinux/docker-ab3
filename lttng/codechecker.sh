#!/bin/bash
PACKAGE=$1
OPT=$2

SRCDIR=~/lttng-test/$PACKAGE
BUILDDIR=~/lttng-test/build/$PACKAGE
RESULTSDIR=~/ccresults/$PACKAGE
REPORTSDIR=~/ccreports_html/$PACKAGE
URL=http://${HOSTIP}:8001/Default

TAG=$(git -C $SRCDIR describe)
make -C $BUILDDIR -s clean
rm -rf $RESULTS
rm -rf $REPORTS

CHECK_OPT=""
[ $OPT -eq 1 ] && CHECK_OPT="--enable sensitive --report-hash context-free-v2"
[ $OPT -eq 2 ] && CHECK_OPT="--ctu --enable sensitive --report-hash context-free-v2"
[ $OPT -eq 3 ] && CHECK_OPT="--stats --ctu --enable sensitive --report-hash context-free-v2"

source ~/codechecker/venv/bin/activate
export PATH=~/codechecker/build/CodeChecker/bin:$PATH
CodeChecker check $CHECK_OPT --quiet --clean --build "make -C $BUILDDIR" -j10 -o $RESULTSDIR
CodeChecker parse --trim-path-prefix --export html -o $REPORTSDIR $RESULTSDIR
CodeChecker store --trim-path-prefix --name $PACKAGE-$TAG --trim-path-prefix --url $URL $RESULTSDIR

exit
