TARGET:=googletestA/googletest/build
TARGET_A=googletestA/googletest/build
TARGET_B=googletestB/googletest/build
COUNT:=10
HEAVY:=10
MAKE=make --no-print-directory 

test: setup comp

setup: ${TARGET_A} ${TARGET_B}

googletestA:
	git clone -b release-1.10.0 https://github.com/google/googletest.git googletestA

googletestB: googletestA
	cp -r googletestA googletestB
	patch -p 1 -d googletestB < using.patch
	if [ -d ${TARGET_B} ]; then rm -rf ${TARGET_B}; fi

${TARGET_A}: googletestA
	${MAKE} cmake TARGET=${TARGET_A}

${TARGET_B}: googletestB
	${MAKE} cmake TARGET=${TARGET_B}

ifeq (${OS},Windows_NT)
CMAKE_OPTION:=
else
CMAKE_OPTION:=-DCMAKE_CXX_FLAGS=-std=c++11
endif

cmake:
	mkdir ${TARGET}
	(cd ${TARGET} && cmake .. -DCMAKE_RULE_MESSAGES:BOOL=OFF -DCMAKE_TARGET_MESSAGES:BOOL=OFF ${CMAKE_OPTION})

a: ${TARGET_A}
	${MAKE} TARGET=${TARGET_A} COUNT=${COUNT} NAME=A bench
b: ${TARGET_B}
	${MAKE} TARGET=${TARGET_B} COUNT=${COUNT} NAME=B bench

ab:
	${MAKE} a b
ba:
	${MAKE} b a

comp: ab ba

heavy: SHELL=/bin/bash
heavy: setup
	${MAKE} clear
	@num=1; while [[ $$num -le ${HEAVY} ]]; do \
		${MAKE} comp;	\
		((num = num + 1)); \
	done

clear:
	rm -f *.log *.txt

clean: clear
	rm -rf googletestA googletestB

ifeq (${OS},Windows_NT)
bench: cmake_benchmark
else
bench: benchmark
endif
benchmark: build_benchmark benchmark_report
cmake_benchmark: cmake_build_benchmark benchmark_report

report:
	@echo googletestA
	@${MAKE} benchmark_report NAME=A
	@echo googletestB
	@${MAKE} benchmark_report NAME=B

TIME_TARGET:=user
benchmark_report:
	@awk 'BEGIN{ sum=0; max=0; min=-1; num=0; } \
		{ if($$1=="${TIME_TARGET}") { num+=1; if(min==-1){ min=$$2; } sum+=$$2; if($$2>max){max=$$2}; if(min>$$2){min=$$2}; } }\
		END{ print("Total:", sum, "(",num,")" ); num-=2; sum-=min; sum-=max; print("Min:", min); print("Max:", max); \
		avg=sum/num; print("Avg:", avg); }' benchmark_build_time${NAME}.log | tee result${NAME}.txt

BENCHMARK_MAKE_OPTION=-C ${TARGET} -j 1

build_benchmark: SHELL=/bin/bash
build_benchmark:
	@echo ${TARGET}
	@num=1; while [[ $$num -le ${COUNT} ]]; do \
		${MAKE} $(BENCHMARK_MAKE_OPTION) clean; \
		{ time -p ${MAKE} $(BENCHMARK_MAKE_OPTION) 2>&1 1>/dev/null; } 2>> benchmark_build_time${NAME}.log; \
		((num = num + 1)); \
	done

BENCHMARK_CMAKE_OPTION=--parallel 1

cmake_build_benchmark: SHELL=/bin/bash
cmake_build_benchmark:
	@echo ${TARGET}
	@num=1; while [[ $$num -le ${COUNT} ]]; do \
		cmake --build ${TARGET} --target clean $(BENCHMARK_CMAKE_OPTION) 2>&1 1>/dev/null; \
		{ time -p cmake --build ${TARGET} $(BENCHMARK_CMAKE_OPTION) 2>&1 1>/dev/null; } 2>> benchmark_build_time${NAME}.log; \
		((num = num + 1)); \
	done


perf_bench:
	@${MAKE} perf_benchmark TARGET=${TARGET_A}
	@${MAKE} perf_benchmark TARGET=${TARGET_B}

perf_benchmark: SHELL=/bin/bash
perf_benchmark: setup
	make ${BENCHMARK_MAKE_OPTION}
	perf stat -r ${COUNT} make ${BENCHMARK_MAKE_OPTION} clean all
