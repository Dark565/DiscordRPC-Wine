#!/bin/bash

# Glob script building Discord RPC for wine
# ..may also be used as helpful build script for each project after some small changes

# Compiler settings

[[ -z $CC ]] 		&& CC="wineg++"
[[ -z $CC_FLAGS ]] 	&& CC_FLAGS="-c -fPIC -O2"
[[ -z $CC_SOURCE ]]	&& CC_SOURCE="src"
[[ -z $CC_INCLUDE ]]	&& CC_INCLUDE="include"
[[ -z $CC_BUILD ]]	&& CC_BUILD="build"

# Linker settings
[[ -z $LD_FLAGS ]]	&& LD_FLAGS="-shared"
#[[ -z $LD_LIBS ]]	&& LD_LIBS="-lpthread"
LD_SPEC_DEF="build_wine.spec"
# Output settings
[[ -z $OUTPUT ]]	&& OUTPUT="discord-rpc.dll"

# Output library architecture
if [[ $ARCH == "64" ]]
then
	CC_FLAGS="${CC_FLAGS} -m64"
	LD_FLAGS="${LD_FLAGS} -m64"
else
	CC_FLAGS="${CC_FLAGS} -m32"
	LD_FLAGS="${LD_FLAGS} -m32"
fi

help() {
	
echo "\
Usage: $(basename $0) [option]
-build [directory]		Build the library; default option
-clean				Clean build data
-threads-off [directory]	Build the library without IO threads feature
"

}

# Argument checking
if [[ ! -z $1 ]]
then
	case "$1" in
		"-build")
			;;
		"-threads-off")
			THREADS_OFF=1
			CC_FLAGS="${CC_FLAGS} -DDISCORD_DISABLE_IO_THREAD"
			;;
		"-clean")
			rm -rf "build" "${LD_SPEC_DEF}"
			exit 0
			;;
		*)
			help
			exit 0
	esac
	[[ ! -z $2 ]] && cd "$2"
fi

[[ -z $THREADS_OFF ]] && LD_FLAGS="${LD_FLAGS} -lpthread"

if [[ ! -d $CC_SOURCE ]]
then
	echo "Error: ${CC_SOURCE}/ not found in current directory" 1>&2
	exit 1
fi


if [[ -z $LD_SPEC ]]
then
LD_SPEC="${LD_SPEC_DEF}"

# Redirecting (exporting) functions for shared library
printf "\
1 cdecl Discord_Initialize 		( str ptr long str ) 	Discord_Initialize
2 cdecl Discord_Shutdown 		( ) 			Discord_Shutdown
3 cdecl Discord_RunCallbacks 		( ) 			Discord_RunCallbacks
4 cdecl Discord_UpdatePresence 		( ptr ) 		Discord_UpdatePresence
5 cdecl Discord_ClearPresence		( ) 			Discord_ClearPresence
6 cdecl Discord_Respond 		( str long ) 		Discord_Respond
7 cdecl Discord_UpdateHandlers 		( ptr ) 		Discord_UpdateHandlers
8 cdecl Discord_Register		( str str ) 		Discord_Register
9 cdecl Discord_RegisterSteamGame	( str str ) 		Discord_RegisterSteamGame\
" >"${LD_SPEC}"

# In the case of THREADS_OFF, export Discord_UpdateConnection too (because then it's valid defined)
if [[ ! -z $THREADS_OFF ]]
then

printf "
10 cdecl Discord_UpdateConnection	( )			Discord_UpdateConnection\
" >>"${LD_SPEC}"

fi

fi

# Regex for source searching
SEARCH_SUFFIX="\.cpp\|\.c"
OBJ_EXT=".o"

# Regex for excluded source names' patterns
SEARCH_PATTERN_EXCLUDE="win\|osx\|dll"

# Set threads count from first argument
THREAD_REGEX=$'^-j[1-9].*'
if [[ "$1" =~ $THREAD_REGEX ]]
then
	THREADS=$(sed 's/^-j\([1-9][0-9]*\)\([^0-9].*\|$\)/\1/g' <<< "$1")
else
	THREADS=1
fi

# Determine source and object files
SRC=($(find "${CC_SOURCE}/" | grep '.*'"${SEARCH_SUFFIX}"'$' | grep -v ''"${SEARCH_PATTERN_EXCLUDE}"'')) # Get every source file completed with .cpp or .c
for iter in ${!SRC[@]}
do
	OBJ[iter]="$(sed 's/.*\/\([^\.]*\).*$/'"${CC_BUILD}"'\/\1'"${OBJ_EXT}"'/g' <<< "${SRC[iter]}")" # Replace .cpp or .c to .o in source files and change their directory to build
done
	
# Create a build directory if it doesn't exist
mkdir -p "${CC_BUILD}"

# Function for multi-thread compilation
subprocCmp() { # args: index_from, index_to
	for iter in $(seq $1 $2)
	do
		CMD="${CC} ${CC_FLAGS} -I${CC_INCLUDE}/ -o ${OBJ[iter]} ${SRC[iter]}"
		echo "${CMD}"
		${CMD}
	done
}

div=$((${#SRC[@]}/${THREADS}))
res=$((${#SRC[@]}%${THREADS}))

echo "\
Threads: ${THREADS}
Source: ${#SRC[@]}\
"

# Compile source using threads 
# TODO: Make it even works not only with one thread
for ((i=0;i<THREADS-1;i++))
do
	echo $i
	subprocCmp $((div*i)) $((div-1)) &
done

subprocCmp $((div*(THREADS-1))) $((div*THREADS+res-1))

# Wait for jobs
wait

# Finally link object files into shared object
CMD="${CC} ${LD_FLAGS} ${LD_SPEC} ${LD_LIBS} -o ${OUTPUT} ${OBJ[@]}"
echo "${CMD}"
${CMD}
