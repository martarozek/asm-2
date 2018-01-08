#!/bin/bash

TESTS=(1 2 3 4 5 6)

TESTS_PATH=/home/mrozek/asm/zad2_sse/test
EXEC=/home/mrozek/asm/zad2_sse/flow

pushd $TESTS_PATH 1>/dev/null

for test in ${TESTS[@]}; do
	DF=$($EXEC < "$test.in" | diff -w "$test.out" -)

	if [ "$DF" ]; then
		echo -e "Test: "$test" - \033[0;31mFAIL\033[0m"
		echo $DF
	else
		echo -e "Test: "$test" - \033[0;32mOK\033[0m"
	fi
done

popd 1>/dev/null
