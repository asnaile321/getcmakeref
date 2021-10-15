#!/bin/bash
set -e

scandir='/home/lim/ubutshare/JMC/build-scripts/tmpbuild/excelfore/x86_64/build
	/home/lim/Downloads/tools/cmake-3.9.4'

chkopt()
{
  baseDir=${1}
  cd "$baseDir"
  listfile=`find . -name "CMakeLists.txt" -o -name "*.cmake" -o -name "*config.tmp.in" -o -name "*config.in" | grep -v build`
  for file in $listfile; do
    cat "${file}" \
      | sed -n "s/ *set *( *${2} *\"\{0,1\}\([^\")]*\).*/\1/p" \
      | tr ';' ' '
  done
}

checkref()
{
	KeyWords=$@
	for dir in $scandir; do
        listfile=`find ${dir} -name "CMakeLists.txt" -o -name "*.cmake" -o -name "*config.tmp.in" -o -name "*config.in"`
		for file in $listfile; do
			chkedlist=`grep "$KeyWords" ${file} -nr| cut -d ":" -f 1`
			for line in $chkedlist; do
				i=$line
				if test ${i} -le 3;  then i=1; else i=$((i-3)); fi
				total=`wc -l $file | awk '{ print $1 }'`
				t=8
				if $((i+8)) -gt $total; then t=$((total-i)); fi
				echo "----------------sed -n \"$i, +${t}p\" $file"
				sed -n "$i, +${t}p" $file
			done
		done
	done
}

tryrun()
{
	args=""
	if [ $# -ne 0 ]; then args=$*; fi
	echo "--------------"
	#echo " try run cmake with ${CMAKE_OPTIONS} ${CMAKE_COMPILE_DEFINITION} ${CMAKE_COMPILE_EXTRA_DEFINITION}"
	mkdir -p build && cd build && cmake .. ${args}  
	if [ $? -ne 0 ];then
		echo "----------------"
		echo "err result: $?"
		return 1
	fi

	cd ..
	return 0
}

checktaget()
{
	baseDir=${1}
	buildDir=${2}
	cd "${baseDir}"
	if [ -z ${buildDir} ] || [ ! -d ${buildDir} ];then
		buildDir="build"
		tryrun
	fi
	cd $buildDir

	mkdir -p aa && touch ./aa/1.txt && cmake .. --graphviz=./aa/1.txt
	# target: libs executables custom_command
	#if [ "$graphic_display" = "y" ];then 
		cat ./aa/1.txt | dot -Tpng | display -
	#else
#		ls ./aa/1.txt* | sort
	#fi
	rm -rf aa
}

relatedincludes() {
	baseDir=${1}
  	cd "$baseDir"
  	listfile=`find . -name "CMakeLists.txt" -o -name "*.cmake" -o -name "*config.tmp.in" -o -name "*config.in" | grep -v build`
  	for file in $listfile; do
  	  incf = `cat "${file}" \
  	    | sed -n "s/ *include *( * *\"\{0,1\}\([^\")]*\).*/\1/p" \
  	    | tr ';' ' '`
  	  echo "---: $incf"
  	done
}

clrtt()
{
	if test -f ./tt.txt;then
		rm ./tt.txt
	fi
}

checksysvars()
{
	# give the build dir of cmake
	if test ! -d ${1}; then
		echo "Not the provide the build directory"
		return
	fi
	# check cmakelist exists or not
	if test ! -f ./CMakeLists.txt; then
		echo "Not found the $(realpath .)/CMakeLists.txt"
		return
	fi
	#origDir=$(realpath .)

	cd ${1}
	cmake --check-system-vars .. > ./tt.txt

	python ${Scriptsn}/getcmakereport.py vars ./tt.txt

	rm tt.txt
	#cd $origDir 
}

traceexpress()
{
	clrtt
	cmake --trace .. > ./tt.txt
}

checkmymodule()
{
	clrtt
	cmake --help-module ${1}
}

case ${1} in
	ref)
		checkref $2
	;;
	chktag)
		checktaget $2 build
	;;
    chkmodule)
		checkmymodule $2
	;;
esac
