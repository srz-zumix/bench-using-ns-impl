TARGET:=googletestA/googletest/build
TARGET_A=googletestA/googletest/build
TARGET_B=googletestB/googletest/build
COUNT:=10
HEAVY:=10
BUILD:=make

test: comp

setup: ${TARGET_A} ${TARGET_B}
	make cmake TARGET=${TARGET_B}
	
googletestA:
	git clone -b release-1.10.0 https://github.com/google/googletest.git googletestA

googletestB: googletestA
	cp -r googletestA googletestB
	patch -p 1 -d googletestB < using.patch
	if [ -d ${TARGET_B} ]; then rm -rf ${TARGET_B}; fi

${TARGET_A}: googletestA
	make cmake TARGET=${TARGET_A}

${TARGET_B}: googletestB
	make cmake TARGET=${TARGET_B}

cmake:
	mkdir ${TARGET}
	(cd ${TARGET} && cmake .. -DCMAKE_CXX_FLAGS=-std=c++11 && make)

a: ${TARGET_A}
	make TARGET=${TARGET_A} COUNT=${COUNT} NAME=A bench
b: ${TARGET_B}
	make TARGET=${TARGET_B} COUNT=${COUNT} NAME=B bench

ab:
	make a b
ba:
	make b a

comp: ab ba

heavy: SHELL=/bin/bash
heavy:
	make clear
	@num=1; while [[ $$num -le ${HEAVY} ]]; do \
		make comp;	\
		((num = num + 1)); \
	done

clear:
	rm -f *.log

clean: clear
	rm -rf googletestA googletestB

bench: benchmark
benchmark: build_benchmark
	@awk 'BEGIN{ sum=0; max=0; min=-1; num=0; basis=0; } \
		{ if($$1=="user") { num+=1; if(min==-1){ min=$$2; } sum+=$$2; if($$2>max){max=$$2}; if(min>$$2){min=$$2}; } }\
		END{ print("Total:", sum, "(",num,")" ); num-=2; sum-=min; sum-=max; print("Min:", min); print("Max:", max); \
		avg=sum/num; print("Avg:", avg); }' benchmark_build_time${NAME}.log | tee result${NAME}.txt

BENCHMARK_MAKE_OPTION=--no-print-directory -C ${TARGET}

build_benchmark: SHELL=/bin/bash
build_benchmark:
	@echo ${TARGET}
	@num=1; while [[ $$num -le ${COUNT} ]]; do \
		make $(BENCHMARK_MAKE_OPTION) clean; \
		{ time -p ${BUILD} $(BENCHMARK_MAKE_OPTION) -j 1 2>&1 1>/dev/null; } 2>> benchmark_build_time${NAME}.log; \
		((num = num + 1)); \
	done
