#!/bin/sh
# This script was generated using Makeself 2.5.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="996497764"
MD5="d4f8004212133fed9fad1725b9c40ffb"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
SIGNATURE=""
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"
export USER_PWD
ARCHIVE_DIR=`dirname "$0"`
export ARCHIVE_DIR

label="Self-extracting installer for qkk"
script="./qkk.bin"
scriptargs=""
cleanup_script=""
licensetxt=""
helpheader=""
targetdir="tmp.3X6eQc9iGl"
filesizes="47265"
totalsize="47265"
keep="y"
nooverwrite="n"
quiet="n"
accept="n"
nodiskspace="n"
export_conf="n"
decrypt_cmd=""
skip="715"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

if test -d /usr/xpg4/bin; then
    PATH=/usr/xpg4/bin:$PATH
    export PATH
fi

if test -d /usr/sfw/bin; then
    PATH=$PATH:/usr/sfw/bin
    export PATH
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  PAGER=${PAGER:=more}
  if test x"$licensetxt" != x; then
    PAGER_PATH=`exec <&- 2>&-; which $PAGER || command -v $PAGER || type $PAGER`
    if test -x "$PAGER_PATH"; then
      echo "$licensetxt" | $PAGER
    else
      echo "$licensetxt"
    fi
    if test x"$accept" != xy; then
      while true
      do
        MS_Printf "Please type y to accept, n otherwise: "
        read yn
        if test x"$yn" = xn; then
          keep=n
          eval $finish; exit 1
          break;
        elif test x"$yn" = xy; then
          break;
        fi
      done
    fi
  fi
}

MS_diskspace()
{
	(
	df -k "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    # Test for ibs, obs and conv feature
    if dd if=/dev/zero of=/dev/null count=1 ibs=512 obs=512 conv=sync 2> /dev/null; then
        dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
        { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
          test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
    else
        dd if="$1" bs=$2 skip=1 2> /dev/null
    fi
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd "$@"
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 count=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
Makeself version 2.5.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive
  $0 --verify-sig key Verify signature agains a provided key id

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet               Do not print anything except error messages
  --accept              Accept the license
  --noexec              Do not run embedded script (implies --noexec-cleanup)
  --noexec-cleanup      Do not run embedded cleanup script
  --keep                Do not erase target directory after running
                        the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the target folder to the current user
  --chown               Give the target folder to the current user recursively
  --nodiskspace         Do not check for available disk space
  --target dir          Extract directly to a target directory (absolute or relative)
                        This directory may undergo recursive chown (see --nochown).
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --ssl-pass-src src    Use the given src as the source of password to decrypt the data
                        using OpenSSL. See "PASS PHRASE ARGUMENTS" in man openssl.
                        Default is to prompt the user to enter decryption password
                        on the current terminal.
  --cleanup-args args   Arguments to the cleanup script. Wrap in quotes to provide
                        multiple arguments.
  --                    Following arguments will be passed to the embedded script${helpheader}
EOH
}

MS_Verify_Sig()
{
    GPG_PATH=`exec <&- 2>&-; which gpg || command -v gpg || type gpg`
    MKTEMP_PATH=`exec <&- 2>&-; which mktemp || command -v mktemp || type mktemp`
    test -x "$GPG_PATH" || GPG_PATH=`exec <&- 2>&-; which gpg || command -v gpg || type gpg`
    test -x "$MKTEMP_PATH" || MKTEMP_PATH=`exec <&- 2>&-; which mktemp || command -v mktemp || type mktemp`
	offset=`head -n "$skip" "$1" | wc -c | sed "s/ //g"`
    temp_sig=`mktemp -t XXXXX`
    echo $SIGNATURE | base64 --decode > "$temp_sig"
    gpg_output=`MS_dd "$1" $offset $totalsize | LC_ALL=C "$GPG_PATH" --verify "$temp_sig" - 2>&1`
    gpg_res=$?
    rm -f "$temp_sig"
    if test $gpg_res -eq 0 && test `echo $gpg_output | grep -c Good` -eq 1; then
        if test `echo $gpg_output | grep -c $sig_key` -eq 1; then
            test x"$quiet" = xn && echo "GPG signature is good" >&2
        else
            echo "GPG Signature key does not match" >&2
            exit 2
        fi
    else
        test x"$quiet" = xn && echo "GPG signature failed to verify" >&2
        exit 2
    fi
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || command -v md5 || type md5`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || command -v digest || type digest`
    PATH="$OLD_PATH"

    SHA_PATH=`exec <&- 2>&-; which shasum || command -v shasum || type shasum`
    test -x "$SHA_PATH" || SHA_PATH=`exec <&- 2>&-; which sha256sum || command -v sha256sum || type sha256sum`

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n "$skip" "$1" | wc -c | sed "s/ //g"`
    fsize=`cat "$1" | wc -c | sed "s/ //g"`
    if test $totalsize -ne `expr $fsize - $offset`; then
        echo " Unexpected archive size." >&2
        exit 2
    fi
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$SHA_PATH"; then
			if test x"`basename $SHA_PATH`" = xshasum; then
				SHA_ARG="-a 256"
			fi
			sha=`echo $SHA | cut -d" " -f$i`
			if test x"$sha" = x0000000000000000000000000000000000000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded SHA256 checksum." >&2
			else
				shasum=`MS_dd_Progress "$1" $offset $s | eval "$SHA_PATH $SHA_ARG" | cut -b-64`;
				if test x"$shasum" != x"$sha"; then
					echo "Error in SHA256 checksums: $shasum is different from $sha" >&2
					exit 2
				elif test x"$quiet" = xn; then
					MS_Printf " SHA256 checksums are OK." >&2
				fi
				crc="0000000000";
			fi
		fi
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				elif test x"$quiet" = xn; then
					MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" != x"$crc"; then
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2
			elif test x"$quiet" = xn; then
				MS_Printf " CRC checksums are OK." >&2
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

MS_Decompress()
{
    if test x"$decrypt_cmd" != x""; then
        { eval "$decrypt_cmd" || echo " ... Decryption failed." >&2; } | eval "gzip -cd"
    else
        eval "gzip -cd"
    fi
    
    if test $? -ne 0; then
        echo " ... Decompression failed." >&2
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf -  2>&1 || { echo " ... Extraction failed." >&2; kill -15 $$; }
    else
		tar $1f -  2>&1 || { echo Extraction failed. >&2; kill -15 $$; }
    fi
}

MS_exec_cleanup() {
    if test x"$cleanup" = xy && test x"$cleanup_script" != x""; then
        cleanup=n
        cd "$tmpdir"
        eval "\"$cleanup_script\" $scriptargs $cleanupargs"
    fi
}

MS_cleanup()
{
    echo 'Signal caught, cleaning up' >&2
    MS_exec_cleanup
    cd "$TMPROOT"
    rm -rf "$tmpdir"
    eval $finish; exit 15
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=none
ownership=n
verbose=n
cleanup=y
cleanupargs=
sig_key=

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
	--accept)
	accept=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 100 KB
	echo Compression: gzip
	if test x"n" != x""; then
	    echo Encryption: n
	fi
	echo Date of packaging: Tue Apr 22 10:48:32 CST 2025
	echo Built with Makeself version 2.5.0
	echo Build command was: "/usr/bin/makeself \\
    \"--notemp\" \\
    \"/tmp/tmp.3X6eQc9iGl\" \\
    \"qkk.run\" \\
    \"Self-extracting installer for qkk\" \\
    \"./qkk.bin\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
		echo "Root permissions required for extraction"
	fi
	if test x"y" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
    echo CLEANUPSCRIPT=\"$cleanup_script\"
	echo archdirname=\"tmp.3X6eQc9iGl\"
	echo KEEP=y
	echo NOOVERWRITE=n
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
    echo totalsize=\"$totalsize\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5sum\"
	echo SHAsum=\"$SHAsum\"
	echo SKIP=\"$skip\"
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n "$skip" "$0" | wc -c | sed "s/ //g"`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | MS_Decompress | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n "$skip" "$0" | wc -c | sed "s/ //g"`
	arg1="$2"
    shift 2 || { MS_Help; exit 1; }
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | MS_Decompress | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --verify-sig)
    sig_key="$2"
    shift 2 || { MS_Help; exit 1; }
    MS_Verify_Sig "$0"
    ;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
    cleanup_script=""
	shift
	;;
    --noexec-cleanup)
    cleanup_script=""
    shift
    ;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir="${2:-.}"
    shift 2 || { MS_Help; exit 1; }
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --chown)
        ownership=y
        shift
        ;;
    --nodiskspace)
	nodiskspace=y
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
	--ssl-pass-src)
	if test x"n" != x"openssl"; then
	    echo "Invalid option --ssl-pass-src: $0 was not encrypted with OpenSSL!" >&2
	    exit 1
	fi
	decrypt_cmd="$decrypt_cmd -pass $2"
    shift 2 || { MS_Help; exit 1; }
	;;
    --cleanup-args)
    cleanupargs="$2"
    shift 2 || { MS_Help; exit 1; }
    ;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"n" = xy -a `id -u` -ne 0; then
	echo "Administrative privileges required for this archive (use su or sudo)" >&2
	exit 1	
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir="$TMPROOT"/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    export USER_PWD="$tmpdir"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if test -t 1; then  # Do we have a terminal on stdout?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0 >&2
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -e "$0 --xwin $initargs"
                else
                    exec $XTERM -e "./$0 --xwin $initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$nooverwrite" = xy && test -d "$targetdir"; then
            echo "Target directory $targetdir already exists, aborting." >&2
            exit 1
	fi
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp "$tmpdir" || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n "$skip" "$0" | wc -c | sed "s/ //g"`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 100 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
    # Decrypting with openssl will ask for password,
    # the prompt needs to start on new line
	if test x"n" = x"openssl"; then
	    echo "Decrypting and uncompressing $label..."
	else
        MS_Printf "Uncompressing $label"
	fi
fi
res=3
if test x"$keep" = xn; then
    trap MS_cleanup 1 2 3 15
fi

if test x"$nodiskspace" = xn; then
    leftspace=`MS_diskspace "$tmpdir"`
    if test -n "$leftspace"; then
        if test "$leftspace" -lt 100; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (100 KB)" >&2
            echo "Use --nodiskspace option to skip this check and proceed anyway" >&2
            if test x"$keep" = xn; then
                echo "Consider setting TMPDIR to a directory with more free space."
            fi
            eval $finish; exit 1
        fi
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | MS_Decompress | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$export_conf" = x"y"; then
        MS_BUNDLE="$0"
        MS_LABEL="$label"
        MS_SCRIPT="$script"
        MS_SCRIPTARGS="$scriptargs"
        MS_ARCHDIRNAME="$archdirname"
        MS_KEEP="$KEEP"
        MS_NOOVERWRITE="$NOOVERWRITE"
        MS_COMPRESS="$COMPRESS"
        MS_CLEANUP="$cleanup"
        export MS_BUNDLE MS_LABEL MS_SCRIPT MS_SCRIPTARGS
        export MS_ARCHDIRNAME MS_KEEP MS_NOOVERWRITE MS_COMPRESS
    fi

    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi

MS_exec_cleanup

if test x"$keep" = xn; then
    cd "$TMPROOT"
    rm -rf "$tmpdir"
fi
eval $finish; exit $res
� �h��\U��/��1��JXy�EŜEE���$acŜ1��1;�:3�1�<fǜs��1�9򮮪^�9�<���������3g�R�^����U�лW/��1��}�㟮��k���WUYpUA5�?�(J��`�7�KI��']IJH�����������4���h;9�r`G�6�q�o<Sǡ�q�c���W/�������rd�/1�_�������l�9��G�9=>^�m�e���-̎wG:8�E��fg3�+��L6y
�o�t�^�sH�U
�y�-O��%r�g��\~������;��|����s	�B}��;fwp�hx�6�����ý롲�����
�J�x:�(�s��lzq��]/v+\�Y�%ϝ�g�XF�ܾ���3��=rV��T��s�KuK	z��߇�Ut��僥�1
	-�R�]j;�b�^���R7fXɽn�[%D�O��,�s�r;�wpȸ���P�	?���m�bc�kJ�H?���~~��h~��	��|HN��;Yr4l�����6f˹� {p��cư��\Kip&qXjF�_N�������.-��h�Y�C�iu�P�!�x�{�Ԅ]{��p�P'[�����.����)�q��̭S������߳~��e���/z�t����L=�E�yH������]��]�h��3�C�g�gY�C5֌;F���m�R�w�eb]����m7��8s����i�v�ἓW�5�|�����s�CXX������#z�ED;E�ǔ����^ c��ٓ"S���Ys�Z�zX�~��ƖY�ѧh\xllBDݾK^_��0�V �/Қ��O�IQ�I�mQ��~�]rm�9k[@�wM
'��Z��t��m�	I��#����\��4".1g�gݘ�U�Z#�z]I._}~B���׶��ؿG���6�O{��x�R1	��c�\Ff�Z=�uÐFu�I����s���,��)����ڦQ��a׭�l��c�-)w��xk���C��#^����V����ٗ899��i�v�l����u^��k��y�fʰed4�����gg��L��}�����LY��ѽ`@ߋ����s__zJq��ok��q]\a�G�Q���op.��=�P�K��������9粛���Iʞ����}V���l���{��:7s�q�Y$�"�Jh����0�A�t��А*9?ur�vn�24ϡ!\/Lv,���-���+1w�"���)m�q��}��cr>�����]rZX`���qk�5R7��&yf��y�荥�I���b����0֪���{�^�}���.�i9.�"x�n[���������������i��{�:p4���vFFF�d8f���i�1[��ڏ+}��~���h?fl��T�1c�ُ��q��؅w���z��~�Ǝ�ڏs�c�~��{ُ������8�����ÿ?������|�����������������B���qF���hG�����Q~�_��>_�q��q�/��}q���_���X������
_�����y�8����g߬ǯ�8~����/��q|>˱�W������<��m������	5{d�Qh�q��(��#`=��ud?9��Oշ�B������k�M��C�}��׸�V��^f?>���>��v�N���O}�4�R.7�_�yֿ!5�u`r\���k��e���g��V��q�~�SFF���dȱ��ϱ��l���5.�?�����q��9�cr��3�`"���������<!��hyLA�bO���ݎcr��͝���SM��eI�����)w�ӂ҃��}x���������1&��O��������lx�oR�=q�h�m��I�����C�{o@+9.v�>�W�n��.������������F��pO�7xeb��������G�10xh�[&����~���up�TѸ�>�~�����v+�{P�X�����} ������=mo��;�2ܹv�㎵�ܮv�?�7��BK��K�ްqu���^
���%q��#�����Ao���u�o���>���hr�!��E�e/�4�V�<a�I�lp�Hv1x����/|������f�����`���f��u���NX7�m->������pt����[8
�6���ؑ��i#������2��d�Oo�s��g���u�dzaMc%m����}\� |�-G����3O���)��`#�<<���- �3VqY�wՠg)W��.�;�#�S��O�\�:�-�]t�퟾�t�7�T�y������	��9W��>�g�ؓcG+�C�G��,�wT�х砍�.4 5�q��'6�3�9��3��sܙ]�ø�n}o�j<��LR��,g��cSt����9������&���f�Ո��j�K��>~��{�nw�7�׽~��a�������Ù@S����ό��%ЫF���6��A����`��-��������ޔ�i��7�Ri�[v�k��|�Yk@�ٷ�<_�>�g��r �I[��f��L4�ڐ�R�n���L�02t� ��)�!�g�� g��gtei+ve�V[N�09$����]�\�n㯴��ƹ�l��Φ_0�`�RR�
x��1�;��"��c�L����x�q��en�g,��g\9GWA���a����K�m�p�x��φt�����X����ӹ�9w<W�΍|o�H�z�s��\c:�%�9�εxg?w��S���ҹ�p�������׌m�Xϟ�g=/�w�/���0Z�z֡?�k�q�a)�.c���v�e.��a�ҍ)KwHqC�}��m+g�Gx;����w0�-`�-m\	�+���~�~��f:��	e_[�ΥV�s�9����xN�tn.����~�$��eܷ��mo�G�']]���Q{���bF�v�5��������h~�FqiA�2c�N�Q�Wl���`��b����9O�B�G��1��h��.���������h{���r���k	k����ɃA'�ٴ��Z8�m{�-�����`�[�����}x��P�:i0�S�Z&����>o����ht�hO�O�ˋ�}v�#-����c��=��t<���5�rg�W�w4^o<Z=h���}_����y$��)�nٗ�'��Ӻ��s��6��y�M5�_�M��	\�ܥ��3��	���B��;I����9dB�Hc������pƵ���O���/�=r�P���~����8�.�lL~C�nkt���[���m�[9�9fڍ�l��6|�Gh`�.�2��L�a��G�L�������W���jfO���t�y�X�G8�9U��[cl��$KxR�>�B��\�>�J-f雳W��C�����Zu*>�q���������Xܩ���r�ɶ<N��fd��\�����s�g��{�B�%%������:k;jG��v����Ҙ�/��~3~]�����
�l�]����9�����e��g	'�ڛ�,��=r�sR�|�|aqbE���i잫����ŪV��y����W��NݞU4V�5��z>��l�C��\Hq�`��0*[�<9�u���ɱ)�W8�Q�݊Es"�sZV�e�b[Ux��i@��ƹ���sO
�7�Q��;�N��fH�;G�g���!�9�J��N�U�n-�K�k��ҭ�d?z?�S�p'���˕�\���u��p���5�����a2�i�i���Y ��mٿ���;k:�P���5�8��o1�-B�K|q���������d|�l���N���/u4o�~}a�fl�������ؙ~=��\��뒵�����������I!��N}��1tC��:�K��t�;�7�,5���C�]�~[�o7�M��!�;�~����M�'��&�>�v�|4�k�_�~��o��F���;$���w�������T��n-7�j�Ԑ9	��wbǩ*3+���`��s��*qg6Iv�Pa~���n.NF��ͥ����4�o�H)�]d���S[�v(��yɟ��Ν�t�ʩC�{������q�7�R��X�2�����(��˫����t&jkr+�^ϳߺ��Ql����U�~�n���޲���Im�:-k?�U�ﺻ��nI�װ].�J��[�U�߽<C%�!���>QC���p@�6�n�4J~�t`A�3e��m|-"�j)�n.�Uջ8M�陾���;ʜ��t�/i�F=9��)Q̷���{��ε��G?��)����'��=m��G
�k=�Dϝo�^�0����-ߙ��:W�3���<�7TIY���ը���n�Yv���*��!�z����R�եt�a��FS�7����Q�?����m��ѭ�z�A�1�cv,�Tc҃��C�o�x��a�����1N�Zl��?�<�nnoR"DΑsC���묝7wڨ��6;�Z�{�Ȥ�����z[�_?�
�5��yuv���,����~�:'��[j����o�L�{�dϞ]|ZW�H�Qgq̢������]l���:���ot`Ҳ�wN�����<{|�޿�������]ޘ3����6���������ǵ�L���\��AW���9��U��u�/�ܧZâ��6�~�;�L���U[�����k���1i��
�?�|.�gQ�{k&�oy��]��>����_�Y�yz�~R�e�L؟=��1��߷��I��G�?�4O��/�����;�ߜ�AK:�Y�*o�ݟ�9��upM��ɽRs���?�ˑ�?&&Fz�J�Q�w��Uκ�	�-����y����7�εl/?���zo�C��S&�a;<��)XL�Uhɥuc7m�����JO�q��u���ry=�U�y#���Ԣ�z����F'��>��w�㖷;�}�n��RaO��Z[l��da���;��{�����՜<x^LK���ߺ�nh���-�jT���x���[;/nr%p�oLÍ�s�Z��ؑ�3�o=��֘�;���8��R��gfz��)�U�N�[S�~
�����{�rh��şR��)�طF�	�n	k�،�����f�^�����q�٨M篽|߫`�僓�u~���D��j�/t��GJ�sm�}�6+�ɍ��o?g{�d��;�l*>ܯ�N����\�u��_}�ݪ]�Tq�����V8�N�W�*W<����G���|i��ntg�T�)IK�=�����㖔ߐ�rȻ
��:��]�i��'�ML�����a�����-��F��OGD������ �>y��4o�lU�>O��}���o�ڧ^��z/���Љ�֨�\ݲ�{�y�%����;0[�\[ޗ��u��s��|�~��j���ɖo�C��@���F��Y��:�w���"ۧ���,ߌ���
7�]zI󹹼6ڼco�Kz]�w�kM\�5�����o��}7�}_��#�,u���ӒJ�_]�<'�L���^�ϫ�&���6dػ�r$��:��~�������H��t�Ô�����u���7z�V晽�L�׿���<m�c��|��o�o|�jN����E~��Z���=[�rh�Lq\���]�&�n1o΢��}m.F�	���^�AkV�I�=5��.�M�RM
M��������+}���7��Ǻ-���vlΚ��;�	��7�D�委y������A�Z��|_?�G�
G'�g�_������!So��R�x�/g���}q�����=0���U�~�/T�/W�䐢�c��T��}vΞ#��.V\��t?�Ygſg���3n����W�ڻ���]�7��R1n��x�����\�G�}�Pۖ����6x>ezϿܦvZ >�s�G���Z�km�*����=���J�v(=���}{a����f��C�ֻۏ�8�i���[����R�������Y@�j����er͚�:6�޳�Ò'ڼ��(Q��gD�>[o\���bNg��;�ةWѵm�a��G4^���¥���t"&b���NWY��Z���>�P�\��gKZ���ۙ�ѫ#�����O\�bE���]l]"!(ϒ�/Nn��>C^��y���{Z���wK8�;���s�n
�����C^R���*��ПҜԃ^s>�uO��y}���U�%�K[�}�_9��jP�q���n;8`Q��O��Vh���wç�?$����O���,�|ܭ���?#ϑ����۵>ze�6[OW�xhl�[#S��R��ډ��޹{��!���kU>u�����cʭ�	�{�����&��]b����TO/q/���G~S��.�����{�~��R�_��z�|$�nu&��o�%v�2����.�L_�rb��۪�<8nʰ7]|toĢ��w���yļ�O�˧r-�*������V��~�����=/��G�{���Z74 r����F�s���ڡ磓Z�9Gh~�w�\�]��=hp������~(W��1Gڟ�|�bFۉs��3�z�N�/��p'M\�ܟ��uM��s�RU�]�T�x�Z��cf�˱�G��A?�>I�����䨔ҝ"��]������W�
9�	n�]�b�\/Ԩs.m��S�v�k������ߗ�V����w�{\�^��ω�K���q`�g�������ɺ���rr���\Vr�ݓ=�w�����]�� ��������?�F؝=1�NoZ���d̮�o-���q�*�~�S�~_[�����^�+���zf]�^տO~����W7V��iX��a9��%�ӊn��^�����s��]��������O�2'�-�n�x�������8j���W�\2�BB�����u�wo?����5+Xʺ�T��]׼��qY��`��ot�~�Y������.��9ئGJ���g�)���ly|ˉf%&<+>m�����o?�X��؍�7�]R�s���q���*�8����C�''c>��?�w�=]Z���s�Û^�|���ݠ�G�C+�6Y�jB�y7x�v�&�����m�UcS^OM�;�PD�~��vgnl�;){���0�7����1�'<���~�bW�,���n����u�҉�<9&����ޛ0쇿��{�x^�T߹��U_�k�����{=o8t���bGr�>����Z����qh���V�i��Y�g��u�}~���7�m����{�\�����5{^}\o�a���7�7,T�ǆWQ<l��c�{|�����i��<OM�8f��Ww,7�.�1�����Ը�_�[�j翽�U�s{����^e���ޓ����}y��7�[rXJ�&���Äreޞ����&�ׄ����xݡ�˃�Ţ}*,+�N{�P-uy�KE���:d,)�S�_v�{gY���F�Li����;~z�����V^�5on��m�c6�]�|���-��t��u�j87����k��n�<u�ƥ{��֢��v7[T/�{ޥ#�<����40ut�ʝ�V\����J��.���݀޾-1su��Z�/E��}7�-���
O�lޤ���N�ҫ���3�Gzln8*`���C*~~����W��(�W�A��|�ƞ8����;&	{l�p{�����۹�]��/m�������b����Ga�Xx�h�]zЦ��z%�k0o�o�N4(��x����=f���������|�QXY��چ����®�W����b����J��[�ֽ��Wl�x�j��O���.�rqX`���,Zv�S����]�����P��@a�Š��R\�����<�eu6���
�o��wZ�b���/X�Ñ���*?ݞ��맱rRشO�6ݒ���\�\n֏j:*�L��Ӯ��*�0�����m:ݫ����{ǚǝ��g��m��{{�6S+��.�l�1�s�e��w~�~�7��>�P�2�v�+յiߣ�;T�J����B��m5V��;3v��W�'��<^��";�����Ӝ���}�X�3}���]'4˿�w����O|zyY|X����7?ɱ+G�������nu��^T;>:g�?�H��^j������/�S7ߠ�.�wȿ𒫭w�J�=t�C��#˵�g��E��
l�^�~��^{;g�e+i{~UͿ�鏭�.9�}�ʣa�>�]����א?��Q���!�7���2,�E��K�om��Nl�ƕ�y6v�|��~�5y·�e�h��{�{|v�o�s�A���Kk��Nw��.yJyeTl&�is�xB�s6��Uz�vǥ����a��{�i�QqG|/�����ҋ�em�Cxoj����\G�<�&�aC�ᡡ�g�H)v�\���ݗ��̬_���ڇR�L�WrH���޾��!�]4�܇'�E����c�m�]eN��O�s��E���}���rd��_�{���y�œ�ӷ_W��^���V��w������'�my�k᪏.�k�R�����kmд��c_N}�s�뒵!13����N�k�?������]���6:�C�e[�^M[����=9p"�[�WM����Vr-��	+�ѽ���v��R{���%u~��-��g�T�!�����zFh��ä��B
J�Y�"��(��X��)���n����4��D[���@�5a��3m���N)�<�q����p���w�b��?/=��tf��}J�S`�ߔ��M;����[��`'��w��?����O=��/��-Ϧe��wѶ�Ӂb��ntp����~�)}x��#��|uz����(�*��>��Y����n՘����	����Y<cD��y��lV�`�N;F��l��н붖�/�]��H��#�hg��E�[/�����������^�ns�qк=�����h�;i��9Tlz-۩����X=[��g��b|��AE�L����x�x�ت���r|��z��-�ZW��L�����k����N���m�b%�]H|���� ���v��1���œ�3��ʝ�{ԉ��|��!���<�K��bD�Q�.?�:aT��s�/�+��;��<��M�[ai���ʅ���>��p�ʾk�-s:�ҩ|�S�/��{q��Zِ{���]�g�*>��O���nXx��R�JJن������dVQ˳�aӂkM��߶�s9N��=Sׯ�,uͳ��f��i�}�����WoX�ص��g��s��u�ӣY����~Ẅ́���Ko�?8ӫvͤ����O�_�Х�m�z,|p������ݫ�Mj�~������;O���Ï�*��:;�j������W�u�j!4��1M�v�O�2aY��Qǎ��<!p�=��+¼r�|����_�M��y~�rwC��V�iq�V|ҧzg���]����E�]����دT��kܴG/kN�6�A��y����qqd|�Ə=�
vo��v�����������\��֠��)�=����������n��_����}���m+��W�R��/}nS�������w/�ki�＂�,Wm�s3�����7H>�y�5��+~lT�����濲�i!���}^���[&]y�G��u/��S��ӊ��W�9˦��kj���gV��w�������g=o�Y6�؃�)���K���}7t�KȄ	�&�K��T�Ǜ���-�^=z���r�_�tI�o?W���3���lٿ# {�㎅G�[V<O�Ț�o��c����poO̥$�������7������G�>y�~J��o��.��?X�n���~?d�^'���aAe¼�]�����h��J].�|r(�v���b�a�G�k���"�?,�pg����=��cڏ�:Ͼ��Ȕ͡��%7_5~Y߉S�W8=��ݽ�_�_���j19ܗ�Hkxݭ߃��wrO����w�m>z&ͱ�е�#"_�?ǖ�t��o�_��۽���͈�mWȭ�ߗP��ç����s���m�^N����e�G�.ر�UZ�&��8�mU@ʃ+���>����!��凍���z�}���ݼ]p��l���ܬS���)���?\�Нb[�ͭ�4�r��;�g>}*�������u���g��?,ol�q�ޞ�v��~æl�����0=cZP��3�}JX�:���Е�>�E=x�ǥ��Ϛ��Pϐ���̫���u��|Z�߀W�����t���k�3�/����ɌA����������az?v������������ߤm�] `Z��Aw��|��on�䜳�����~���c�*(U{�;�xMP��ȧ7�����Í��:��׭�޻����U/�mu���'�X�|g��.�+%n�t+���*��rnX�������{�����%뱄��;�ҽ}?�j������u���i\�Q]F��z�O{�����>��s9�b�O�.�N;�|Ȱi�rvm�0ys��b�n�vW�D��_OY�7���
���}.Pt�ͧ��c�����V���1abЎB��:M>��n爵�}䂡g|ZM|1�秜��4��e})�r�W���!iV�S����������������ǫ�ߟ�?���
U�H^�N����I���x��O
.o6�a��
V+Rw����
��uhƕ�g��p��sX�]�g�9�ʧ��ݣ7U�4�T�R}ӷ���
��t-�;ۭ{Iwnt�2�I3�.^��s�J�:E*f�8�ߥ`!��CC\��;e�.��e��q���c�G�=���q�=�UNV��z�{�����-\KΌ~�ל����)�洶��w(�]�����W��7�w�Z���M��s��������9�E�6��m���������}~���2����Om\gʣy��v/�l�;�?�J�Gl�\X/�����f=x׵���#'%�]j��
��z9s7���s��ɗz9Y���׏��ث?�,Z�zl탭zT����Mލ��l#���vo��m��=Ȼ��)=lŧ/j{���v��\�K��v�3���7=^�s�Q����?�XVV?�8hK�>=�dۘ}�'�~�?���NG?�r?}
Oʱ�ʺ�<n�u����/�;���W�}͇���¿��O����������ۯ�����ou��y�Վ{�qb��͆W+>S���:o�U��}x�X�ꕳՔ�׭����;��-7.����k�R���Z�Î��\�O��oΪ����ǵ���o�_�?��<��ғAu�|����d�C����>����Y?�Lpi}hc�k�'^��(������"-iCj���FU�-*;�z�6m޵m���K��]~����K���?�v7-�pn�K���-��}Wo�wi��{������QF�_;Y�sԫ���+�7����EV��?��P��"�*�=hM�wS>�z?�^����O����6�ڈ�K+�v�O\�&�_�w��z�}T���՛/|

9������{~��{�&����ܴ�fD��{�>��B�c�C/��W�C�!�'u�ѭ�����J����ި��Ԧ�+/ݿ���&WN�9��I�JM�o���-������pH�5g�v8{�C�6k�����9l]�ѿ����a�m~���V�=�J��=�����Lq�{������6:jZ���&×_<�m�@۟�rM�X_�ϭ;D/�Z����G��/��g�m�맭�òW�L��s���7���������<gZ����?���oG}F��7��q�T�ǵ�F7�mH�E+���>�3�Ti��h��Z�2uf�	��k9�\�o�m򽩐��ݸ��O���=�ۻ}��]smb�}�C��W���ef��N�;�l���z���wZR�\�����n��>/���,[��w�Z=k��vjB!a�����^�ܹ>�-����U7��5zMv����z�k���N�����u��w��^,�0q��'��L)9�ń��;��A[��]'�9�=G��qc�4���~Ѿ'�L�<w���iSjLt�rp��?��:<9�iR%��DǷ?���ԑ�9sY�M_��=���5G��_<�@p_�`短��=��ż&7���Q
(�ץS���{����w�휿VV.��ʃ1�+���Q��6o����&m���������܆�m�m*���cu��t��v!1���C����(w�۷���b9jY��I�ˬ�<��c��qݵ�T�`����]z�|���o���8�4ߎU�����ܸ����z^�;����/7���e���-]9zîc��S�ߙ{�z�_�_YtaǼvu�,����]�>�J,�z�z��N6>v�ͫ߅�C����*��y$ϱ��*�s��}��ת��`��Ǔ����l��r͍���%���ys.|��8�c�P��-�6�V�I.�J�g߽1�س%�j�}z#ϑ�%�D�������T<%�n�9WVu�\^�9suiz�<�C
�,Z7�@�'�-�����e�N-6�xx����~��rf���79�qk��t�wy��]޵]����ߋ~n2�n���;�=�v���w�㯞lݬgƵ>?&�ruZ�h�l�
u-�(q}١'��zDt�Rgm��{�����r��E;5;�tA�.'N�:���K���~oh]�FOD�VewF��;W��1���i�����P�ֿ���Ҟ��\�y4-`������K�(Tw��R�;'��}�幎J�fs�p��g����\��wm�;g��U<���U�f�OG,���|h̄S}b,�.|��mt������s��9�z�%?�kɹ�9*ŏ]0kk���mݳ|�Ԁ^=N�KK��[����a��?�_Z "���8��7/x����w
\���gЩ�����Ke�?+�]|��k�Ħ��\��Lkx����F�ٵ��Ӎ=w���˱Y��k?�ִa���-���z���_��;��n��WW�3��N��r��{��%������9gd�;���"�fǾ��0��NU��/z����&-�X�����;O�����K�i���-����&��������sf9���ҵ�J�6,[�xnL���.�q��l�ܖOc�m�i{�ֹG�[�ÌS[#Z����CN�=k��gw7<�V'u;\lw������|N*t��\�I�9���*�7�8$�g�� �S���V=fbޖ��t���'�ydFz��..������I�f�ܹ۠�<�/nٽO�M^O+��</+������]}(�f��g��n��~�Sm��5c��x��3z6*s�C�^͏�_\!߈��pߒ��n�����}o��?��4Υ���i�ξ�q7�����M��Q�p��q~?_�=��n�=?vn�bOU���{n��c׊��i������٥3o�jSlx��W�zjc�W��每�?Z��-��_*�-{2"��s���y��֯��q��^���b�]�����6������ؙ!^1o��>���ַ����^Ѽ���W�M��1�'�nxf��sE^[���"7v��6J�v>#��G3S��-�\s_��O�*ϝ����Ug�JXڣIյOV�m�y�n�weoV�s��̺�2j��lk񏛷�*|�g^��^S��&D>�ܵ�W�A�,}����;���b��mĤ�Ǳ�_y�}��t�a�^-��x»G����5�����~��l�_�30��E��.�+�v���C�x��?
����'���O���~�~K��QmZ4�-)��t�,��b�v�A�&��5�v�u�����p���x1~���/[�.:�h�mZg�c�����r��v��U�ο�ޡ��&O�����yd�ނV�^��(?��f��<'�T�*ի�|~�G�ԋ�����!EMU{�\�J?��ǧU���R'̍;��O���8n��K�v�c�m�L��2|��g��(�pv��Cƕ���n>��|���_$zp�Y����\Hqqς�w��)��������8x����s��S�ͱ���Ų+����9\Z�||��>ݥ��c��ٿ|jJ�1[�<�X�U�J?��ع�i���/CK<���T `��>�r�<�u�ԿS������-w���S�G������o����Sm����lTݙ�����[?�O��nU�S�}������}���������Sn��%�g��bknx�qo�I'/�����E�����R�����?8�D-�X��-(�m���֭����X�݀f/�ږG16�-����*��Q|��6���5�qF��''�)�;{����&7y�a���>�S@�97�:p:����;����o�{��]�Y���Wm��O?�n��nd��Ŧ>te��f-�S:�X _��S��LK�v�ԕZ�S֬s�>�p�ڵ����>���ozy�b����Ϙ�pӑ]F�~������.?�k�G���M�[N�=t[�;�����t�Ç�~k��>�-<{R��.�^��:#Mu;�n��#m:5Y�r��n�z��|����QթÃ]#�DF��߻�4qy�N��<��W�^Y2�S��Ow�J���)VǠY�Ϟ�Y ���_6�hR�Q-=���b�u[=�ݮ��=�Z���#C�o<���M�f�Sg�-:j���s�9qn���ܞ�!ǐ��������ٛ��6t��t�7�� �kn��V|���\��|}�U��O����m���ݫ^�R��Y��7
�=r���\9�fN^�b䉰�o��}�o�|���!��yÞ����4E�yu�?���,ٴЯP�v�?�^V�a�����z5Y���¸4��]�|�@@��-�\���(w=�¦�sy�������/�!�ɳkb�
]��z�����ī�>�y\���k����
���>I{qdY�r�ǭ#����V�y�#��9�ש��'L��}�UpLk5��s����i�6�j����?�n�	/��-�����J?4�P{ڙ�{>\���o@ۛq6��zz���ԥ�O�y�=�Uz���y|�l�}��k&��'5rܮ�>w8���g�7�-x#r��w}����Y2xё��[E�p{��m��l?sk����¦�E���2;���_�\s��\�s���HO��ۡ�'��^�k��vIx���m�*�u��p�G}v8&��	��'���X�3p���EO�X�f)Z̩��s�����pעr�l\����S��v�}ɱӁWS~
|�:ʧ�>�G����x�%���]z����+\�����x�״ļ3�lr�i-n��N[�S�K���w�Na����],+��;w_��w�������)�Œ���;�<�t��nW�<��E�����̮y3�����b�N�Q�������;�*�x�����왿dބ'�^V�|�-Z������.�{���mo�(T�u�W��?�o�aܲ�m�[*7<�Ms�eP��{oo��s"N�o-��N�c�r��P:�o����*5�ƈ5A�_Y\����ا�1�˽��a�JW�[]�5�Y��z%�ם��Ie��~�<�[F���磌��Lȝԫ��K��������n��Mr=�uk�����cǠ��c������Ǽ��+Sl͜!�k�S��ʫ�s\�����w���׻o��~�Frځ�|��4�MϺ#*���.��ξ�f�0�S�?��/z�S��5sķ��Z�W}<��:u�^f~����~�=%��9�+ۈ?��}P��p���uo\������c���rܫK�n�W�6k��y��?�7���3s�m��J����
	^o�eL�r�A�}n�l�N��o����	�N�1j����x��C��X�S�-�T�C���� ���M"ڭ�U|�s�z�6��Z`��!�{���8����n����N�s!h�ڱ�󥵏�)V�p��U#=�����C����/�١���B΍�س�����mf9��Ʊ���}~��Ǖ�C�{�U���<G����,P&�ΐ�kW^Q��f�{WJ|�����������ēͷ=��7uZٙZR���ޟ�d���]��������~}J�v�qd�K%Z4���A�i�T��&����[�j{�pr�����-0;)�~�.�=�ic�;����tb������0�״{��Pr]��lsh�����\˥�y٤S���&t:��x[���'w��c�fu��ڗ�_Y����?��{c��c}���khņG�V|X�N�ۼ|b�y<����cĶ��R���z=��[�������5{�Ya�#�ϻ"���R�=ú�_�l���X�snK�.[zuP�^oYu�e͕<Λ2��˦�Պ>���t���W߶��h�폽�~=��a��������8�Ϗ�>���<?^�Wfd��㿦�l|�r��2�¤��CJ4������+S�4�5w��V�����>s5�U@�X�g	e�Aۣ?�U��X�ا�z��z����W^����u�<xM��U�[w^ў���wͅZo<�e�mS=�w������L������UC�,>�ӥ<�˒���s�PW˱
w��Uޭӌj�k�H��A-Z��dsphۺe�`��� �����x8x��t����-ۋ}i���?���ʸ�/�O�0�]�q}����o����yߝ��c�g���ٓ�ߓ}���#8c����y�S����104p��l�#G�?r	�80�38��WR��I�?!�10�L��Y�'?���禋��Ӯ'�Ǉ?�pQ���#����)E���;�m4��I�+x�'��������ڑw���s��ت�]�E34|�t��-Z5o�!��@��}�Fm�,Q�1��H7��=���t�����ఞ5�_7�r���Y�D�$[���,�obxD/k��o�-�b��Zڶ�`���F��»w��$K�͖X-  %��r���f)ǚ���+��d����?)�G���]��"V���I���������[cc-��]ɖV�dkR�����a>�{f3z�"x�&��r��ρc�M+<a�+c8�U�y���a�Z�o���p��C=�;���ө�OFOW�����y��Ժ���,����+'�}�5�\��4[�"�i�y��ѩ��q{`ƽ.郌��"���Q�  1���P�#�;�7v��QJ���'�蟺�}\��d�]׌+jIr�1�o�!�>��r���p�{�x�v+�O�dd�ʸ�~�������V<���C`���F'�}����+ۄ�t��"xI��Z9R�62�~�Fۺ��?��~������WM}>n�p��w?௞�O���+	7��t�0�S�	�k~-f˛���O3��v:�lq�Y�V�oCƾ��5���p%�����\��t9�P��J߷�e<���i�.�L�]!��ǲ���{;v�����V���r���{���Q��șw�~�B��YB�mX����n	֧���֑W������ӌÁc/��ֱ�c��o|2�s8���^-gꇑ+�v�*��v�k�#�w_{�׮s�5Y�FR�y�2�m�������M���Â��������ɜ�1��m?��\���#[��Ik�`B�d�]����8?�J����2l�{l�8��X�9��	�=m�߳þ��#�u��t%�M�cm/}j�Tx�c������GܯV�cknWύ��|�2-�#�`���B;�g�̲!��Hu6Tx�}�딍����_�@߿���^��#��G�<�]�c�)����"��Q���[ɿ���V�n���IpX	��͛�1�֦���3�������{�^[�q���m\�޷jU9Žl�b������\꟭S�zPP؛�;�����lү|��&��-�Jl��'��8u�>#_��ޡ];v�Wh�)�6jךOu^tL�܏=��ǖ�Qh�^Oݧ��1��s���Z�m�"�(u�����F�=�~�۶�?�m��I�+;�C�zXʾn2�����ƍj��U'�U!p�_��O�C\�Ҫ,������Q��0��������ϖR4����ŞnN�Cˉ��Hsv�eT�^kbp��O�����V������#W�����O�u���O�خʖ��ʖ�q��}����orE���+�H�2/7���pT��UӃ��:95����5ת��.����J�{n|�K�G�����ݕ5�<^�Y��ǣ��Jɫ�]i����R�5W�mڲ)r��z�����lܵ�����|�l��p0w����<��p����\���/[�b5��L)�h[a�S��}�Nou��J^�\�2{d�[#�;�G���~m��)R�{��ᷜ���v&6���m/s^qr��$�lJ���O~��ȩ�%��F5�U-��N��W
hه-Jyp0�G��sk���s�ei�����ћ]��-�=���	�[�s.g��C�4�2�WWs7�r�*e���3�y�jw]�!OĮ�G2
T=x�ZJ�5~����'��������Y�Ç����8���\[���o�n~���u�_����V��ؿ�_����o.}zk�_���wͧ�7/�~�2�֦���2��~h�k��NI'g9Y���79ar�6�Wn�'���~Z�⛋�C��u�[mD��O���,���gl�
�:!ip@� [����φ޼?h�>�^e�A���r-|+1������Z�/v}�+�K�]����Bw���%>:��-�I�ri��lk��N�6)OH�
K+�������M��Sf^��u��IM�F�)�7�rwc��U�R5���:+�{y��B�;�nDŕ��x�50���*t��I�3./;��c\�֖$�@D/���snoύo�����hk`;9�J�+�/��!�g/�z�I]۝�iz�y�������J�>+>ϡ_�8*�;%�㣝�M�}�uh������>���f.����=)��.���씒�{�|����[ԬAz�w�~�[��ش�e�'�ғ
�to|������k4�q`�zżls��~�~l��{����2jH��#G�_U�ʨ���5��gv�﹆��%��W�E������ߨz�u�v퇅vk�v��⹛�N����-MK�������}���7Yߪc���z�*�FV�p����E�F�'d����Q��R�\s��+e���1I����	�F����2ֳ$�FΈ�����=�'�幮d[�Vh�����_R�I�ˡ��[7m�P"����S�z�X��-����8T8���OqO��	\%�����.��������ӌS#>����l�GyE�$9c��S�e����]N�}z��W����O	�OeK��W�l�y����,��+��e�p�Ǐ��wO)���F��wL�[+v���l��<�M�I/����ew�=�i���eۿgH�+/��[�O��P�]����!/J�qa���1��~�a����1�́���+�~�u��Ð:u(��N� C(�!^�-!#�a�z�,�m����R,���(�i)y?�~�Z$)y�����ɶ$C��Hp�5��5)�9>��G|�b���k�$$���_?&6�/&����{��m�W��C���&=�^or����?ιC�>;�IJ�I��V<�>�C��ޮ����19�6�p����l���7����Q��"��8[�â�����}��EG&�������y戹z��	�핰�V����	q�;cH�ns����]���S�ɹD����!)�
89׮��<*�����^��z�v��s�������Uk�wr~:jm.K�N�32��?����Y���1jM�]-��1�̀t'�l��S��,\��sG''׀�Cj�����q���p��]�.�Z��9�w�����s�1.Ή�w�rHm���zM�.��j���W7ct�;�ޛ���#[�"yriC������\<c�+���911�2��:̬=9���{�=j/\�xoޅ��������_2
8��]���}�V��P�|��#����P���5�,�2�\,S|G�gۚz���Gk��8��;e�z����_���K��~k���8�rr�=�N΢E���;��ǀ�K΍?�8XoZ����9�j��w<�u��ǯk;�q�\=��A���l�k������G��q(�cmG��EJhR�ڕﾹ���ӅE�sO�톪ܐ���������[8���lc�������TZcNI���������M
OL4T��������?��DA�������������_�2�c���'G��Y#�,~V�WgA�C���=��a-;�!���{���+ߛ��Uc��L߱����6KJbd��j��OG=��#�Øxc�E�{����%�?�W)���d�Hk��.%'�y���Ϛ�l��ń�~q5"�/d����0����Ո�C���dlx|�/�Ņ��꾔�/���/N�Z�}q�G��3�1���l\HN��օ��/�|���1�=��`�������/�a��_L|T�gS����ϖ����������]{��	/ky�����kﭚ}w�X��!m�j�t���1($�y{�9�8װUPP�����˭UP���h��hԆN1�3ޔ�i���#�M�LV�Q��^��F���rkԪYPH��I��X/�z!��f��`\h޴i�fY�$��%��;�y��{cFݟ���扖z@CƎ�?w��Y��i5ZJ2�?�R�U`�z�aM[��A���
��LJ��%?�_������.�tA�tA���E:�d:��5/7��/�/���I���U��^0we-�؂E���HRTA��D~u�l�Q�RE�=�{{�TQ�*U�[2ߣ�=*�G�"W$~́(��"������v>�ik����&̰3�ra�>2�~�/ww,|8wH�ҡf�����Vn M�W���RE�L�n�f��>)�e.��/˙.+ocR2_U2]U�U-�U��rw�D�5�ݜ��cG��_�����>3_��ޤ��wN�7r�[�5<��h�J_�	O��pі�3��[9��-��>�,^�=1V7���d��<�\(�*>�N��Z#l�Ȱ�I���5��5I6�����0O��&�}�f��7l���*�W)Ջ���I����-w�`6`�Qւce��k���Esj_�^�.�
,�0�L��&���!�7����ަ��玥V-欺�c�����7�K�5_i��\�e��~�%���r_|7�����FDlB�����h��)~�q�?f�N�@���#!�G�59!%)��o�+�sĺ�р_w��_t���eޯ>�C`��T�F�{?���~I���?��^�`��j�r����fk��A��d��T�����<e���uTg���y���R�56����4�W.벲�۴���M���G���� ��e��o���׻y�;��:C8����7���RYbl�-*!��#���[2�$ :!�C��*�'ED���$Y���V�Pn@f��g(�V�g��{��$�,d����7i��5��Wϸ�m�����i�������髇V�7�������/Uc���G����,,WJ����&��۲���&��*�'"^��`���3�%�Y��m��k����q���]��]�.�:�zv����X���_o��kih���m��m�vo�{��&j�	qaI��{�_7�r���{�-"�~#��;���u�>��b�^�2���8�'0�/&ܕ}ڗ��/�� z�߾-��|c�*�E�/V�������J�9rC\�J/��Y_o�ǚ��"\|�M�?n&U5���{���3���E��B5�ު-ߒI�_9�����ߍ�)�v�Y�_n#Hq�w��H��2v�Ɛ:3I��.�wK�nɸ[�ww2)��ݭ
���w�!�����Ԩ����N��_�k��"l$�����m��\���?��������[�B����F�4]���wԿ���f�͎|����2�E�t��	������6oͿ6��0C53G(,�����_?�BO�)�U��+�������������^kx��o�����G���?���TK�oR��6��4�������J������?f(������c�R�3��C����1#��?���}�aStY���`��������_��kːWf�ȴ.�W�;C�}�AP�Lk�)���jA�k5v�0Է/�w�j��l�>}����o��}ҿ���@=x���Q���{��~q'���x$�T�r�OYjִ�\��Wڿ�kD��n�jl��������f�kRRB���x]���l�J��i�t7~�E`������Z�;6/��\� M1O���kZS�r�(�u�S�Z5o�:��_�F!A5�.��)~߾~�Դ�q/��+ڢBZ'�9_Rx_\$)�֤��x�5��%)&*�_d@���m��Y�����KNI6�������D��h/�@s.[��-���C�-�"Ӻ��u�����+ �Pz%�����������=zńEZ���F���4���b�+~=%�R�^M���+�Pɉ���Ʃ>�r�؈����JYn"������ȸS`��H�z�n����%��Wg����K��k��떏��[����N�!�k�F�3,�����l��e!-������ˌ�����߅�����/Q�eM��%)���_�[�_��#��&GGX�Y�
֢������5ޚaim�����H�I4����ĘXk��k�fm-[��Oɖ������1�)����HK��x͎���NH`̴����8lq��?��fmQ5�al&z��%|��Xoq+k����rs3��f��m(A��pKhKM�!�=)P�=���\Ū_�v������������ut����U2�6~E���0K��YT�Β(��΢f����EQ�,ɲqM�bmH�q�xN6���eE���j�c=����C"�H�/�NL�i<-�������������Y��Wɝ%A��w��=6�@���Xo���4���Z�"Y2�ьg5�cTDY1�:���Ȋ�񷱆�,����A�~Hƨ	�ѶѾ����s�1�m6������O�w�~����{D�;$㼤+8�=Ƭ����O�_�{ֆ1s���7b�wHF�%��q�$���'I8.�����ݒ�NYa}4��RƘ�Ўq�`̼f�C3ƃ���¾�hˠ$Y��4�X�6��.c��*�}�o7�i�Ϙw�-�^d�l|�h</J�pLEU�1dc˞1���3���c"�y���h�o|����{5�1>"��>�'�w���V�10.l�m�+���UlCb+Cb�c�g�d����h��3�76��ƃ�3�;��h��C�vd��:�#���M�0'�U����&�D���1��}*� �3�b��e������-������6ƌ>��&��!#7�a>Eh�ѻ(�v���0�q �Y�v���Y z2ƃ=c�ƒ}�A˲ʾ[�������5��� �d�)O��!�G�}Y��6��1UpNU��a��ɌV�1�`�}��?��9�~��h��*�WE�b���x����gs��%A{�v����� ��븞We���0:�kD��Ӝ+��W]4���~}�d���q�Ⱦ��Kׁ�$X:�7U� �����;��2��!?b�x_�0����ƍ�b����>6����]�#6ނ
����F67�ڄ�X_e֮@���+�㋌���?e<��	;f��֤�Ǚ����/�����VA^���ћ��ܱ>2fߐe�m�ne�A]���s�*�η7Ɔ�f˦�A2�Dܢ$ ?�����-�%B�v�bS)K�i��F.���]6�>�<��^�p*��N?cQ��0���m�-A��q�51֠K�!d�b����:n52���cEl��tI \S�ߢe셽_`lH�m�-3٪A>�-�1ص1%D�L'�G�E��h��`�א�0��ط��2ƕX��.��1HAE�α-��� �B��@�`�I��4�f%`=
̱�KB6�悶H��ٶ�]�1$ցs&)�OF��1w���c�0�l�16�( ��Ÿ���� [����hIRh�+Ċ��U`o�]�m�PHh��a\�7��d\v ���B���+̕��[�1��6ͶVAA	ے�[�� ۓ�/�_`IЋ�X�&K��H�p^���X�`��6���Nµ�	0���ٖ�l��'�Y�~X��x�"�����e����.kc�1��hT���෣��s�֪��3[��,R:n�"�!۾A<�4�}��@d�* {d��U���O��Ux�be�Kc뀉!�;�d�ߞ`��0�ƚ�[�0�*�~l��B�e5�'��}�B"��n�n���p�8!��,��k���+��<�E� ���Q�2�ŋokl-��"s�%n�"�4[�"��&l��z���4�*m���L��H|�q�u�"o�b%�?$B��"�c����= �9����5��h�P���|DGD��[�K�7��]����U�w��#�8*���(����(n�� -���Z"S�V�����E`�/F|A5i
Tx�� ��5�`�PL�oe�ƃ�x��}3�=�,����D��$p���ƃ%14K6�O��1�%���蝭�D�N�@�wq�fj���a��0Ř�K6�2k�h�盉}�h��DB: ��h�� �0є���1�}F�'�+��*�yf|TA��x�Db#���hoHő��(f[0?��lS��=��u��!�c�b�w�.�>���8�
���H���  �C)��2�*�,�����L�$r��x�J���]��GFàVI���M�/$SVB9�	́B�$�TG��Pm0�胩5�k6g���v�)�<K
�5&�h��dP[M5Ƙ�y�w̥����d�3u\��*��ēQmYQF>� ��
��lʨ:�<�h	�2}hħa�t�拭u&32��(���X�IM�������h_d�J������ {|��
ј@ꠦ�:U�]��&��`*PP�P��8c�T}a�j��� �}�!�E.�L' ��1E^�2��r��h����)���v��V9Q��	{8�a�V0Y����W$e
6 ���& ��%�uAHE�ְkdK�^���V��e���d!E%���yƷ�-TSds�*���}@�T�>�<&�Tq6&$㲽D#�P�a< t�>	eQ��u�w����vs����/�w����r�� O�}�4�QEվW��t�X`���
�'Q#�KSv��`@���m�ߢ��-�)�K��ٜ�1Q��NE�Vx�H������kd�PHƓQu��1��2��P��u���ʮ�xI�G�^��!>���K(S��B߄��y2�eĿX=�gH`ި�/�djA~���(�U�Q�2�Ĕ�e��tXx� �����k�#k(C�h�Y&����%��A�e�Aߴ��:�KES���膤h=�͵(�f>�/*�y	��T�� �`l�RACeA��c�kp�,��	�mfn}FƵ���
|��/��k�'�̢�4G�{�)�2�s0���	D�ʽ��%�P�"�[�=C�w�9�q]Țlʸ�7hn���4��I��j���t�qs#�$�4g���)���SF�*��ܼ6
v���_a�P� zm0(�hv3�	�WT�e����	M6�dn�� �k����)��&�\������S�|��4g1����?@�a��=�ݼ*�yt
M�@���?��Ӟ�f4Q䲧�6��3��S위}ٟɼ$K�,+�d��p�Q��W�=����It-�+���yPq���YB����nPP�U$�G���=��/6nl͂�]-h6���qp�(d�%�!��^s�
z�v
�Ȓ�����*�y�&`�F����	�_M��W��Ci��@ڿ5t�Hd��@�Q�e�dj��"�x�^$��c�����-66���	�S&���8fܝ��m2�1���B������)��0��4�*�*pװoyI@}���@�t-��^�u��z��E]
�wZ�������4�S�%B2.�+�G�w�<���,�ֺ
����dYF��S���B
�s0�+�s����-�Ռ_2~<L"ہ�.�w�H�PIV���]bν��
�T�Xk ����0/��vICN"�]�(o+@k�L��ؒ���� �]��"����c߯��JC['�Q�}R@�t0�:`C��MJ|L';�
�^�p	�z"�d��="����q�TCyd,�D����	�Q��d4�����uuг�>/�]�"����`����ߺd�r���T�I w��]���L��H�Ff�s�:d�Q��i�0�w"��=ܱ"�+�l)�<i��Q��r�贏���O'�7�[&g�^2����
���`ca��d}�zW�n5�۶@�D�!��lKD�)����-�z7���Sҽ�L�"�����|ɞ��,��Ѽ0}���2�!E����AD��H|M�vZ��c���1q?�����N.n�0���;�?�d7�[��4>֨?�`�@[9��H�V$����)�~Kr+|��z*�Ge�1)(��Ze{���2@H��V���ncX�L��ng�1��%t��=��dX`��Н��'((C�x��U@����>I|����=�)�_E����2�+��G�?`�����h�?��6j�mu�a1�-,��]94�t@�l��J� �ǵ��Ȱ Sk���(� dDA]J[��6C�tw� ēQ.]OEۀ�����
l�*�KD��� 7A����W0e_��]$K�m�PSƕQ��i�@WG#��U��p����a��)È$���U&�B��ŋ�!�Y�'�� ��`���*�A½��&�\I6v��ye���l�;U���V���&��D��44+�d���{� �ާ����a`o#Y��:�C5�%�Y �*�wH2�<�/�|+�g�>� �|���g~��!��4`Ȯ���r7�X�+�N/���>(�nVu��$�e����DҫA���$�.��]��u	�d�̲%��h{��6Gp���4�&�A��l4"�K�|r lCY�P"��d�3�w0���Bēa���Eٔ��ד\�
�e(g��c4�}�"ɲܶ��dd$�<�ʈl�En� ���T&�\F{ӱ/ Q;�AnSu���KG�3���ぎ���%��4�^q[��f��ؼ�}]G{7���W%YM%���-�F�/�h��[t��F���)�4d��4�?�e@�St��*�) ����@@��pɟ�an`;�(ACT����>m�s� # {�Lv@�&@�А��G�_E���5����Ȩ��d�D~�s�	}|���<��#� �b�?$��߀�(���DF:�A�=�x�D>wv��4�4�&E'���#LǴ۶؜ �|ؗ��{$�y"�|�U�>`��^��9�'�AhgE(���VE�vC�i^ ���ZfC�Q�@�H�h������dD�*�0@��My셠��(cI�?�o�o�+�9����)�n'݈�z:�y�`��"�z%��H"�=
��$�x�E;L��*��%�/d�c}�Ɇ�I&L��TC#�f6
61��� �F~?ܿ�N@t*���
��D�d��V�9E:�5e�_t����X@�J@�[� ���2��|l�_E[��2���@~g����@����o!q}�톚N~��~d{`���k�l4��	{)���Sh,�"!��bGPv ��	��h���I������KT�{��`}P5}�`�D���̥��/d���
�u�}���@��vG	!� +��w̗�6q��$��?�����$�h���ި�>z0�U�ܣ�~���:2A	e�U$��}P��PvLc�vF����@:��{,ȗA�%�[�� 춚	���>5S�F�ڴE�H�|�x���t1�pj߷5�ӹ�X'�ǡ�dK����a����$��Z�G��EV�֩��I ۸`½I��Q^F?2BÁ_3vr���A�%~
> �ノ)�d��ɗ� ݃�K���W�!�o���V�h���6F�qa� ���A@�}���j�K�F�T��rx.ػ8d�׸�����[��9$�ʲ��#��/��%�8
e{X�
��i�$�c	i����l�:�́��~��3���	�r�i�����;(d�弚c0�ib�P�����u��E�@YFۻ�H��袝�R�T#��x?�@�T�}�[��ر��� ^���P�n��ԕ�-���X�a�Ug�(���|0yR�?�2�򣍟|7���?[��~
�aj��r?��x�)d��}��גLL�,s�;�)�Q"a&Џ��%��#�Z���@�a��pۦJ!(藇1 [*a�%JCr��::�2�h}دU¦q<���+n��o�O�a"�C�2�
��7%���h��A`]�(��[%���=i�u�M�'����1�#��.<�#F1L*�_%���~�;�)��ۆP�E�3̏B�3[_\� ���@d<�YC:�E�'�/�:�=LCG�b����l0*��(�+d�P��i&|�6��$[<̱����0�$S��1�����ю�{*�%�m��F��"(v~��&�%����$��vEǗ��Ǭ f�ˈS� ����@�'`����Ds vZ�J��/�^� �L9�gc��� f��໗)t���U�QF��yn�$,�����^�WoSq�h�	��[�ч��:
�<)�G�%�}����v���1�� +�9�/°�mV�}���e�7�?D@?%���'.�BC{#�z��e�BJ���,�+
���J4�/��n��b8��0�1U��I�k"���oA�4�U�\ "/ ��
��1�ls�GF�XB\��2��hd��B<�A���We�E�ƛ͉Ha5zD�����I��~ЋE�B�D�G�G�O
�A4��o̸\#
�$��o��d��p��;���$��D�"�W@�, �H��L�C?��8z�&�s�)��p����C���
��+@��6E�hHA?�J�	2�����K�#ns�H7(�F@� ��D�:�B3q�!n[2c�_���6d�qr?���J��o
���Lݴs�Uڏd�i��"s��tu�������`KU0�IE�)�#ɾ�~G�nE$��J�5�ݲH�>ԕ@��W�u �*�3S	���n-*4O
���N��N�U����,����S}x#ؓP_���_��R���1�O �#�*@fW#���#�!�g2�<nץ�Rc�p�)�;�?��x�-��Ð�VRȗ���
�7���(fDA<���>s��|�" �8���蘿W�Hσ�q cD�Gm^�K���=	}&�K'�l����8D����1fC"�'[�ZE�u��#S���Xs��
� M*��1�AB��Lx\���߁��t+�E����M)��h}@d��<V ]��?%ڃ�+O΄-���%�qhό��5$�\�19v��L4�1V2a�I��gD���)��M�(����TJ@2<�g�>�ϱ��X|�cD�[��*��%�6�mN��P�����chd�8�D':auo2�L�	:a.9�Z#��H�L���_}��î��JsKq�
e�F�6�V�>v�����#�
��3&	0ohKl<��D�񚲶`���{��U�#n]B�*nS���oE�&mʈ�I��}��`o7�R"�S ��$��\���<_�2�A<�h�18�J8�[`�D�ˋdG��"�=�QBL��Q�Z�T���q\7��r[��;ˈi��/��%AF�1��U�v��I��#��Fۇl�Z �cx�.�!ߕ�Na�{�:'��#G���l�������ր�F�q���=T�� �8�wW�c�D�I��A��J!��|�G�bl9ƙ�E��K]&�������B�*� L/�W]1�F��S�>b�ςq��E�y4�p�sG,�?��Xj�Q ۝�Q,���9_�4	�+��.qId�e6|�1�����7mJ��@"�#�UR��^JvIF��(ߖ�q'�M��E�������}Z�� JAk��M$�v]̴!h�QM�4�oMߚ�� �}P*Q�8p���ܯƉB�%�バ^@>�$���(-	k�Ah���A'<(}���$��kd'=�R]��G���%��4��QǸ�H�X�2�F���i, �(fS�G�ܢ��M��Bl�Hq�dcWQ��E��R?Cr���p��_�������/
�=���a���E�wa9٪e��CH�Uy�8�lR�3��*R���V�����A01y"�y�8k�U�,)�>!��a����S�C�b��D���<=� /D������'r^"��B�5�V�0R�pM�����S���A�E���0�:�%aJ"3�%��(P��H1�����㦑tL��jG#�+�/Q\;���i�a\��<���)e4	�2\��tҙ���%������2�5!��T�u>e��y�H��ui����߅H�@1�47"�K��`}��,�S%���J�'��i���)��jbE�b�t�C "FC�H��ў,�&�4���/Ľ����鯘�F�y��
� �X5}Z�;i-�>��8jkNX91�O_��t"�+7�k;m:<��l��)#>��V�ԮL��`�D�dc)S��(/�^Ǳ��z:�.H���4��'D����܄;h��q0@��A'6��Qȕ!#>p:�-$�=�$�+D�<m`��1E��}���Qoĸ��ļ"���'�)�2ډ0�O�|"�m�|R�]�t������q_7�4�]@v5���|��@� ��=�����Б/�ޠo:����WhO���ӐU{<�$����3�h7B}���	ug���(���Q4sf`,+ڞ�H��ʇ������4"ab)��=�l����m	��/����JO����p/���S�L�TE;6� �q^!_���7�v+�	᝔RJBL+����ѻT���LHr4��A;b�D��K��U�Vl�ɨ?)v�67��W���1fU�yD���{E{aGU���<ςB1���p�xq
;iG":�bQ6�|&��P�?l�O�0�{�~I��Hy G�;َ!�Tc����~Dv`���_1�w��>~:ʹ]�-�bKE��0��7���2���j�}�Ҙw�@y���E��}��F`����>/ �ctd��*$G"&q2b8�^����'B�'��L�

Ǡ���S@n"~��?�tT�[��
���ݏ?����[�(f|����h7D{b�a�Ҍ�r$�������#�o���k|��5�S�a�9ƽ�D$�<�6�)�p����[��o��&����r�IS��X ��m�L�a.+P�Hy �
�q�"�}�69�dt��`
a5n���)�D�'��l��(��G���ǁ��#�u�!�|@�/q�J��x¼����B�<Y�)U�n�`#����m���<�G���y�tj����ԉ�i��i���<	
�X�K�|/���`+U�ߧp��JvP���|�����Ӗ�MR#�C�� �p�hK}Q ��@�%3-%��(�LW��ʤ�k`O(�`be�e��>�I�k5�$?�pD�2� H����bRY�� Vq�CC�#H?�XK�0�e41���@<�o��@��ߨ���E�S0�ۂ쥐�A&�����B*�p�����p�����sa�(?�F2�_%R�݆x{�=cXQ���� YL�M�#ҒN~��ȤG�OG���B���<�>�/�6�qF&��I�8Y&���KO���q�:a@9��)R�,�rP�U��#����f ٱ�'Jd��xP���d�t{�^�#(K+&�p;"ɩ�r����	�k�b7E�r���.���R
ѪN�/���qcA��=K���(��(��������R(���W��y���h�Z�`�	CD�`*�k���TJ����bU��>�1���
�?FXxIʺ�ކr�	�=��Pu�[�I7���л)ؑ$���� ;1�:u��j���������l��$� �7�Zż�"�0��/��J�Q�955Z��O�c���)�Q�H^@Yl���� P!��>������SD�'l�� q>����1W�db�0���c�H��MF���P��RB
k�;H(k
�����g�hldՔE�ˡ�UΔ�HF6���oQ#��߄��b��W�X�����:�B�)�n��_�qD�)�&� �J�(�ś�݃0j�=�Z��w��+�#��y
����Q6}'���ߠb�C�/���Jq���j	��/z4Oͱ�:�#*ځ��"�%d³s{���{�A�4�5@{�D�p�ᡐ����0�/�&b�	�;��]�Z"��KAO"������XL��M���ԕW��]2�s2�ޣ�2���|*h���Bq/�L�<o �d��2sݑ��>`�0�(�� K�f����vw�͙)�)���-��D3h���H`�%�#5��}IV)��	07d���D��V���]�q�(�6�&��y��4���7�"��p\1O,O��sQ,!��53"�m%��mc�Ӫ�>#)�s�L9�(��L�IT�m�(��s���v��d���s'���Q)ރp��h���a�'��!&P��Y��!��(o�EPЮ�_�[�x�B��%�;���8��(�	m��Q�uJ|D&�#ǁ��_'��,��3)�r���cpE¬�X˔P";�U�nbj0�cU`ߕ$�WJ9w4��-s�&��.��O�}��p.�૔5�I���q�J&9���p�D�ݫ�XR��XA����=��$Ӟ�|�J�?X&�Dy`u�у��W v����[��v?�q��)�_�:�;�E�B�����r�N1$<.�L���h����\`��Q�F�(�~�Qy�b{�FxE�	R�>]4s�Jd�����e)uT�dC���I�5�Ѣ�<��.�E�r�$�"�ٛ���|[��*�W���� ;�w��Rӗ� e��;ֆ��:�H"�� ��@�RTմ�P| ��J��V4>2�+��J��<G����2�ZSO�6[n��������`���uʁ�m[2ŀh��G��h�I�--S���s�I��U�T��h��u�B�"t$Q�0�!���kV�8�{�<q5�D�7d{\�L�8�'��S�d�4��O����U��2���>#�C�>'�.�m��NR�<�(���"�gGy��� ��V�g��W�xz�o�2aie����b.5��P\�(����ٌ�i=� F���*aa�0\���i3f��$�o�~E�Q��Q�j�^j�L��u�M8��"��8Q�� 'd�D�U$R> �Š��A�)�c"��gt3�BD�5bD%�a'��y&�w�T.�rPsc�IG��^�����ӈ��dU溚�/D��e��F9O vR0s� nB�ʎU�'��W�ܼ�D��h�M�����&D�<��+��~�k¼���Rnt�s��&�|#
�1���b�D���\�����q�R��ǋ���7,�Q�9�t�3ڌKy.[�����sśy^��$r̰���r0��L�@�b�)�J,�/Z&l�����f�=A��;0_)�M��H��F��2�9�6��� ,�����y~k�r���.�����yܽD���� ��jcP|5�~�L�=�̵���o'�O��R�<ʛt#���v;���WW%� ŧ��t���M2��R��M�b���J>v�kC�7�X3;N	���]�u84�⃩��>�_%�_]D"��dܛ�ƇN�n	�'`^"���
k��,
��qͪ��%����/�[S)n S���:�_�zd�EJ��i C6�1��%��D�L��+�L�B4��;.XB�=b��F��Q������*E��!�s2	�#P&���T� b>K��֔�W�Q���%�t�d�hK���J�&�}[A�<�@�u$b��'�ϩO"�<]Ǹv�����f|�i�B6��`��b��Ŝ͸��<"��)�
ș"�S�����q�"z��g�eF�5bn0�9�D�+�R0�.b���P�_�g���T#,8�#��$���1�]���$*����KF�y�53��a#���"�m2偒Ig��s[�Lqg�OM�'e�^�H>`�t'���)3�]�ӑr6p߼��MJ�ө��_��r�`1ʙ���t�O�t�J�?�y"S�=��E#��\	yy2ž��\�"�����AL��6L��㘶5�j4�:�H'�����w0��b�E[)�\e����p�@��@�t���x*�(QY>Љ(>Y!ܢ(R�$�.
*�2�M��Hy05b���x�<Y��Zz�<C<4��������<��C���t�/Wy,�@�:�Th[�e���xIR�9���N߯˴.���Fb��(�=ϻA5�$�gMSIvȮC�_c%��c��f�H�N��[&�#���Ub�)�JD�<F��O�Z�R(~Z��֋��o���2���e���*����jd�iR,�Dy� k߳!&Q��>�Dxb�do���'�-L�����c�7'�C!ۯ(P�h�=����N�,|�B��L9r�v�h�AD\�N��(϶Ly�\Y���18���)��,�[�+��4qf�3�r�T�LQ�\l"٩�.�
d��v:��!qL$�1���\阿�ƈ0��~�p��c& o���^�!�T7�bI5��&Ɋi� YZ�'H1G��}�$۪���f��L~*5�J���bnE��cnk�J���K6� ��S��*����F��OeʯMy �Lv)��~(o�f�p�U��R�v�s_������d��e�1@��bbte���f�P��b2� ��bBx�cٴр�+p��nϝ.Ʉ�vd�Ǻ�d��qb"ո��'��{ �Y����1�!�W`�4أ�ޡ�k�`\�DJ�;��"P�T��$��O1��h���xr^�k��f�;ϓr�&���MS*QL�$R���b�6���ߧ��Me����"�Zc"��E����;P�Pk��-q�O(�m�Xׇ�eS]����*��戔��jIf\�8d'��&��QV�('��� ����Ho乐0�e�����{'��h-�����AN�%�7�>�\������`WV�!�n`�U�g��)�W(߻*R��G#��̋/R)S]'H4}d�b�ū`�`��4cޱ���(���H��QyNb��5���ֲFu$��x�`ݬ� |�x>�I��}_�y�Q��oU)Z�8f�-�o x�n��C�
�Z<g�Lx/�=B>l��I�E�3��$3�&��D�r9��E61P���	�a�S�I��<SC�7�*��'����'	���A���H1��m|
a��w"r[8��"�쩂By?�V�(�<�*���9��f��c�I�B�qhX/O�\�� �̨)/��p?��R�i)�嵓{� ݞ��	"�m1�0�
�#�We^#E%������3��@���1�9)O�'4�!X�L�}�1
�-s[��~�jaQd�Ukf�1�3�1aK���ѧc�"��l���ښ@֥�|�Fb~�����T���O��q�Q(�M#����C��ڔ�>;3�F��T�V$����p2
��S=W�O肉݀� ҈�swj(���C�6,`.p߲��%Z��D��H�S2���B��E�%3�
b�`o ��Ad�-]�X̿.��]�)׵ �<���
|T[m�W�n�G��A�Z9�*Kt/�8X�:�F� s%ڱN�/�}�d�T�9Nqk��!�{�nC���(caN8��"y1��D�ܞg�I�ZH�f�#�(f�j����ctk��M('���@��@�Py<��)�㥸�Y�:��W�|B
ٚx=KY1�� �q�0��j�g�����f���	Do�h�9CYM�9�u⟢l��F�@�T��=s��x��t���Q]J�̭�lʿ.�u&^�D�n@9�D�ֹ@8:;؃43�9֓#[�J�[(O�w�R��A@�yMP�]�6�r�r݋���du�Q�ٞ�M�XD�]�S�/��m��>H*�.������6����W�0c�PQ������L���$��}*�<?4��I�o�=-�E�=_Q�6�~GyM(G��u��d�Y��,Q^pE������ģ4݌�7�Q�I��j��E�r�P\�ET�]�h��f\#���8M�e�5
Q�"��B�a���2�N����pI�q�
�l	?B����3}�h;�\�(w"���KK�ɟe·a-h՞wC�	�A���m�csu�l$�/��g��,@�
��I1s`s�{"�܁>�5.%�?�6�9��v2�k�7^��\j����O�e{��4s��m�fʮ0"�LQ�Vo� �`>&�r�?G�5�9��gb�1��P�:�h��90�G/R,�@�$�	��캩��S�������$��x��c�z7kk��QmF�r�Ʉ}#݃�$H{�=�5���x��+Q��$���X��|l�d�i���.�T$�p,~h���E�:�X�@���|�h�P�FymT��h�5�J�<P��+�.R<`ju�s�8��}��A�xH"���*��yjd�������a���9�'����<_��<O2Չ4�9jT?�縐u�=KcOu:x=E���a�lSh�5ҝ���L�q��	�>E��������*�3���뤯�N.P�m��`N���QNG?�w
�:�y<�N�
��
Ѻ��nǳ��%ʝ�9D3�1d��$ZG|�1,�<�����0�B2�!��R3���^$>G1�k�����Q��U3e:�w���O2�D5�¤���? ��z�v�4����f�1�Ճx8���L$S\�d���;t�|�Tߚ��`7����������f�4���))C�xj���=c�2�`(.�j# ގb3U��։jaL�hbzA�d`�ǪS�Y�;C�H�-���_t�6���4�%&R~m*ڪ1�� 3�J����jb�	�%�.H1�2�.���M��c�E�O�
�d��<�ϗ>�_�/r�F��e��#�O�a	P7��d��&Rp�u�XC��.�(�D�1F��u�^�MD�{�3��|Yio����oU��ad��>l�(
Tg�젔����]z�� ��`^^uv]�q��$�_؃��su��K9����'9cy�ʉ�R��LyX%�{Q��|���R� ��c-D��ژ�1��
	�)cܘ��\�~ꗤ�j�.�勾s�j �
d;�ꥈ<֓l�aC`/�쵰�)�@q�:��|s�j�CI��B"��N"Ʀp�	�.e���	v=bryNj��E��Z-��D�|��70�>`b�@�6b�y}@�!�����m�r�p;?ՒF_'外e{~�'b�]��d��<�(�b�ʻ�s�����ڨ/P�<o��F�����B�h|�)"��fE����bd�&�}��ބ� �UB���f���4����{e��:�w�i�����B�����yL2�[Q�i\�����x1^�c�H�C*��H�_P.�un��b�$��F1ǒ���<k��k�� k˙yA��/PL�h�/�UڇT�a�e��F9?d��`ȯr�Bu$^�c�A�+�� |�@�qI�\c��[&|�L�
�~s;?�(�V��?�D��h�dR3�4�|>�@x��(�n5|�K�5�S\��:��^#��f^Rn��M"��*!��`� ���Q����C8֥�^,Qn#�CD�8���_� �׼�E��ɘkB�yX��y
�9a¹o����d�e�Y&����CWɇ/�MBD�|3�1k����|,��1�f���S��3I���P�������?�&�~.���\n'yZ���2��"�
�xF�L�?�슼>�d�뀿�Z*��%�'�4��&��!�$ʭ��z�l9�߯�d[$T�]Ւ��!�LL��*��(��H�.߿��<קb��0�!�PI��ɏ)Q/�r`�ݏjJR��
�[U�Gbn-�se�ׂK�Ð([��`�l�E�}^��X���W�5�yNѬ@8o^OV���y ۈ��Az'�ϑ`�{�n&�T��b�eʟF�� ���NQ��O�#"�ЦNyhtG�+�s��<�ݢ������{͎yE����53͚mw�u�y��d3ҩe��MT����<��ĔK\���:ՏT(��u(��8*�C$���)�X��QMs��Q^7�|єc�.�n�ǺCvٜc�0ވpi:�k)�Ï�r�y�d��(�X��ȩ��v���H>+�����x�@u���
��^6�ᖸ�HP2�I��P�:=��Z�U���n��u���Nz�J�D�S,��XY0s�]��9X��xS���.P�3̓$c*���q�kc�\v��%{.>��Ʉ�v:�IQ�f�$��#RN~M��c�-��+�66��t��
To�փ�k,��5:�CT/��T�9�HG�@�8�5S=:��M�5Q%Ӯ�5w9�p�<�Y��F5��#Q�(��O���$�E�Xq���z��	�Q� Ӈ�����D(�׏e��a^@�U	��sw�h�5k�R<�H�ĥcl�TA_��D3����C�)W���jh�=
���i_x�;��$�:��$�|$�kLL`��w�St��K����
Ĝ�s�Q�t�I Q����XQ&{�W���ò}�H*�/��M�|��iR�Z����ܳ�ܥ ��T���f�2��Cy0D͌5swh!��Du^�絧Z�H�JIߑ��u����P͔�j$(T��ro��PR�<�ӭQ<�8H<���̥��
��E�s��Nx}VqؖJ>� ���	k��>�m(�#��M"�n��I����#V̸P���%�CH��������"�@��Ynۢ��͇��&�/�F��Ǧ���L�xa3��!_�} q?
�q�9��S.l��P�j�_�8�<�k����dB��g"Q������� ��p���X�B#�հ����+��2�B�:�����D���)�&Q~.��
Xǚ@u�3׍L�p�qʄV�<�<_�D�����l����."�r��؄ݔ$3>s?�z��~���M_�#	���cx}�sS)N���M5*��&S��ED9�LS~ �rj
�iHo�L�k^�k�k�RnM�0cX!c�bL���>�y1/Jyx>N�s���5�\�I'��5*�0���º��o.KQ��S�(��N�I9�0�ձTD3��'T1N�$2�)�o�vL�d�ɗ��nb�F��J�3Ú&h�[�fT�@�yL� �V�?D&}��G�Ѣ#��A4c�$�3^�����L5:d��1ںi��(���s��(��ʢi��)S�i���}�"�:*�I�6w��4K��˃|2��/�ۻ`_V(��,�/C7��eN6a��$���2X�Y6�C�D��ޖLr�j�]�XՌmI�	?�� ��v@/��N���J�v�ik`A[�f�@l(�U0ǚB�W��	��|Xo�j*�\�*��u+�UHG�2����2�=/�n'R�?�� ��j�h���(�jf=U���)���u��@y�d�L2��~�_��<�
�Qu�+���0P4ch$��p��f��+�\>:ʧ/�}AĜ��][�XfQ����
�I�X2ч���M�6��r%���B�0ʛ-�:��0�dU6�J��c����y�K8.��u5�u�@vT�=s �G�C����N՞#������F1������M ��2$��U�Z��$�ή��w�T;�rbP�u��
C")���ֽ�����;��{��:�H8";����|�9��`n����3�Xz�@sK9W�#�\�<�jp?*�����c*�od^������`�5�)*�T;�K��N����/)��q��F�D��/g��)���"ќ�/J��
��~H9=�<y�q@l+�qu�SrۖH��(�H�gb�y�D���<��Z⏄�Ѩ�����b^	�)��o#��D2:��0�}k�ړ�)�xT���2ɶ0v2�82��"a��Z�L���Y�kΨdS�n �ݨ^+���\�i����P.%�bh�&ߨ$��M���}D'����v��c�3�	�.
�3�5�Y����~�h����C�ߨ�܃�a�2��a}X��+T�Z��:�b���O�1P�i_���yQ`/�t��Z
�S	�L���ݲBx^�G�:��Q�]��4�1�N9=���`.�[*H�W�j�H2ճ�8��,�Yf���q���Q>+�1��͓Ȗ+��e:���T�S$܇L�y��N�z��,�k.)�#��t��f�RX{<W��c�	�cgu�ρ�Kf,5�"d{,4ϟ~G�|IDc`[�����&�"ߐl�!�x���#��
D��H�:^І(HDl�*n�� �T7�"�k�I��-�,E��1g�@yE�v:�ن�^��P��bT�ú��]������M|�L2��։eS���)��?�Y�/���jpG�8L��%h�f�5c��1�L6x�w�\��&��v�����%�`�Mt%�C��̴(Q�=�Q8&֗H5^;N1�_dZ��'_;ǥ�
ǌR��[�L��:�]���Y�Z���g�X�dK��DD����?P���_� A$;2�*���]J2�"�N'hTCN0�p"���Q�=���P0�����$��:�߁��v�����/���=�>�Luh�,J<�/ն���<�(�!�b�`�纑(n���@��y�E�; �(�� h���-��L��(�2�h���eg��y�d�-]�::�k$ ��	�R�����^/Z�ɧ��/�h�ׂ������`]H3�(��ZF���h��5�
aK��*�Wj�o	m��ՐI�Zm:��׃��D^_ڴ�aL4�>�kM(d���6,��9��p�1���N�>T�D@<ڽ)���=���R�3^���&��	̚��D�'��2�l��Lr���P���j<Ϧ@4��${̻$�D'�B���©( ��c
ck����O�U%���ܛ�%�!]�ۓE�簣��T��x�;�'	<��WȪ��$���>�k�j�Q�l�ǉ
"a�%�Yk���J�Z� ��S"�.��܌�`���<5
ayd�� �d맜��'l�J�!S͢L1x2��x�A��u�Qצ�h�y�3??��Ѿr������ɹ"���:�� �1���FZ�b��gK�Ia߹�U�>���]!2�j�JS���p�N���X� ����_�py�{9�y�G�G[��w���w�ק3��JU�ؠ�-*�O�DkT�a� ϙ���N���.)6����g3u� i�8$���K4���Ogi��9���T2uK��%r%��?
�Ph9˦�(�+�L,dz�)�S�$��EOc�m	_*;�����;���/��[��NgiA�3�#{DBRpKi��]���*���g�5wi�h����$�hv���;�ѱ����ק3�R5'uN�Ӈ6�0P`��E�]I���٘�X6���g3�L�/C
/_/�o�;��%�\-%�l���dR��'�,���k%����t���A������쓥[	���i����٪��5d��J���HKB�.w�T
�����H�Ѩ"T����ڴmT�"����S���bK�D���Z�����Ho��n�$�l��I1�6�f;���m�!��뷚��vO�a���O"�����6���	r��5>�{�ՒhK
��Zl�Vh'�g3�ت~P�F�~�1ə�	�L�K�m�mۺc���7�f[ԣ�	I�,}clі�)���'�c-�����w��1[L�%"!>�f,��$K%c�D��3槦e��1k^�n^��z	���bzD�,�`U��gio��n��ubc�'Y���'$��Eϴ�&ƲA�D��7�ֈ$�͒d��D%%�Y�"-�H��&'����0�'�GJ�5ޖl�M�0��s����o\\x|d��;9�O6?�C-������g4��h|�_��y�H�_|!��?9ˑqWld,6�~�|��6kֺy�V��,Ơ�[��Fs�x�0��U���a͂:���ݑ�D�FE��GS[��!97����ً�Mg|WL|DlJ��R�����l�-��o�N��������o5���٘��t���i�Q�O�(U�KuK@@\x?Kr�wVv���1Q�'�,ޕ�b|��?}��*��T�Ԯq��ذ�������D&�gs߇�m���9��:���1nIf�a�F�;c��)��	n7Z�kZ��H���f�T}*�OH���a���1���dK0O�����Z��eg���c���ꖘ�a�re{'�F�5�w�1]�g�d4g\1���Û��SY�r�1fǍ{|�\���E$���%�Bo��n�wቖ��H��DcE~р�D�ž;w*~���q�#�����_���� ���Ԕ��o�ө_���:�=��5����퀀�Dc5آ�:�&%���Q|Ok�њ��ct�|d���|����~���M����@,��ެ=g�3V��Q�^f�޻���b_|]��7�f�g~�?�B4C��w�I��4zc3z��|����2��xs�-62��1F�¬�>�Œi�&�4|5�>�>�6k�eaf]��6�]���dY�߾�xCdlr�8o��3B���^Y�ʿ|mx��$��O�ub��lO��D_ⷾbOx��?���[jY�,���Q �o�٢�kZ�U_ч�t?�x�4a�W���,��D��YjX�\�ˏ5�VD\�7��̻�{����������0�p���S�y�~�ڐe��@F�����h��b����NY���j��Y��}��@|2N$�"Ae)s���(��>�8���dv:�y�+�'|q+��n���ݾ��g:g���f=c���ߊ�����DҪ�R�Mk,%������m6k��j]�pE�����e�u֎t�Va�i���[�X{���q��+�m��+kØ������n��	�\��
�c71R�����Z�F���w���Ou�T����{{Y��[��[�[-)�F�����m�I�����V�
gmI��2ض�z���mq���]��m��;�J>��F��Wl��%g��>��xvo�5��I���5Y�Y������F�<�>�e4ࠗ٘��b���H���O0�aL!;b���G���������
�y�ؔ�7�g�ʬk���YG������ه��X��&+�.v���]h��F����C�u�@c�|CO�bQ����b��%�R��-$E��4�
Z��nXP6[Y�~jUM�"5z��a�7��ֆ�chr0���p���_1�������|�s�������)�'3%�"zYm_���/ *&�fM��^IƱ�֥��j��90)"�A�5�Mv�����jKJ1�Cj&�-�oDD�dz���zS�},���>T�E���m����?����A-᷉��u��ae��C���"R����m���g[�1�	�W�y��TX`HH��>�]c��	�a��)� �V��	��1:o��3���=!��5��������o�O���7�����Y�z�a�ha�b|��i��w_դQH�q;�ulB��y������3�䓹y��ٺf�S_���d�*�Xk�[X����Dc��c�D�%ܒ��aM����I��m\����g>�u&�$�䒬��Ņ'�4�gƎ�qJ|�'�=QIV�7�¿��L,�k�D&�Wd*�� C��c��D�X�9��z�i(c҃��$�O�,��x�O@��P�Q�?rMj����l�)hK�2Va3��P�b�♅�.�)�Q�5�x�ۇz�dU`G��i�57���a-Z5j����ß`��gh�^�R���m���j��o��h�[���~)�}��6�֠QH��V��
�Q��O��R_R-|��	� ��16c5���^��RT"��� Ι���6���Dk��W���@K�������>��l�Y�=��8\�u�m�!�w��4�W��GR�W����F��n�O���MI�6n���l�?�VV��^�u�d�`"MDTlx�d�Wl$��m�=q���0m�S̀��j3(И�zl�]A���E��/vg2��x�k1��`�?����z}�H��,�&'|q����S�Y��K�&Y����$cMj��h��뿹I��2ECXOI)���P���XR���cg�B
EQ7�9���,
�B�)˸�_�(�����D�w q��̳�1����Rh��@�I��}��3/��&�#�d"�T���!���Q�B�����r
Es�x/�Y$c7���5�g&[�uiK`ۏ���z>�
p��YGi�E�0���Av~f��Bf>�������6(���LZ7j̾z��²p�$�zK�]7<9�<����՘�*@�s_+��fQ2_�G᫛��
_���?���C�ˤHd>E*ŷ+����1�i��b�쁭��)P�"�5j�0�1���-��FX��� �~�c�����E�����!��F[q�����>�I1́����9˺4���Q/�j(�F��nv��WL�XYkc�G胳��JbV��J����������e��&[-�J�]׺�Z�QЀH"�7d	����a'b�vk�	�F򇡍�%���XQ/k�0vrڏ�ߠzs�ˆ�M[T����̧#�mI	�p���4���㢐:�}0�4�܆%ĳ���0�) 뺒S�چ�&A�N��������l��O��h��qG��O�;��/�H�򖤯�INm��8��_���;اd�����8fV�r��⮈�����o�]���L5n���fk��tˊ��%�'��^hqc�_7�/�^�P��D�R�Y�jħ���A���kj�����IBR�l:�z�OMl�x�lz�-�vnU��\}1hWf��o6Z>�K������k��k�e���,��W���g<�y �p�L�jut�U�`����2�u�l�����7�3c���l�r�*"��!80#4�N�����M��	��=%**T%�L�'6�`_q�ɽ|-qՑ�3��ꦌ�&�����1�M�!5���B�������;`�e���v�J�|*ؿ��YO�B=��;�_Ï�k� ��y���M��A2����3�.#�d����]����k£��'�����Ss��Yi��5��Υ���gp��)&�V�j~A���.��k��M������?����TdJ"6���� W��$'G�ǃ��x)�.���L�g����{��3��n�Ə�TN�Ğ��!�1���C�b����#�����ƕp\�������_Y^�Y�ӒF6����8�7"W�#����]�kx��!��m۠u�N]2���,�w@�� C�bʤ1R��"]�l�ʦ���$S���b�it��W�k����z�)���~�5N���^�7m�p�b���l�Xc�p�]v�z�zBEp0�K�0�8_�J�X,�mڂa���V��d��e�
�ݠ��k.�X���A���ٍ���]�z^a.a3���ođ�b����� A�_��=&>�?������`Jd���zsJr�W���{��/u�p;���H�Hkr�ܕ��nޓo?���ɠ���y�5	�ęf���\$
0��������u��ʘ�B��!,�Q��b�̃�m�C��?�_��GEE������k�Q&�2| ���,,�S˂:��a������ ��Y&�7�r�E���>l^�j�$l�]�魮�4m�5�v���K�[�%����eJ<� ӗ��"c�.�16ZE�Br0�8�e`44��h���&ܤ��"Tc���v�	���Ӿ��6a^ïؚ�	٢&/��Z�(Am%*d��=Bs�v(E�3���z�Њg���=fog��9K���br�|N��r�~(����~����
��x$��5Z��(�TȀM4+�����˝�|���5��h����$�Y��%�����7E����sL��_/��U�_X��
H>�\�N��ɧ��<���
�˪�7���)��*��Jg$οÙ!?����H;����a���D�]�݋km�����C7��������i��t�/YN3o๰����b�8���Y�dOs+�*���b6�胑Y�W�e^8�t��i�����$x ^�)�f��qJo��X�74��My�`^^�y�� ϡ��$���BG >�jIK����ty�� +C�v����\����D�X�p񉈴�����o������%Qb5�č�+�8<Z���1^GBQ�H5���`�<wÚ5V�	!�2�o`$:�ީ�]���7� )<ޛ??ضn�*ڐ�]�
"o�F��W�u͚x#<\�:c��Vc����x��Y�4U��k���9�<��,}�9�!�VC�8��f��C�a9~���{b��'�����T�|&3^�2�m�N�(1��O��2ԔťS{+k�~8J1�Q.ly�e�������l�m���i��ϹЩd|�i'����Q.q��]x�өB���W���VW}�bR{+G�핦���s�*�&��ؐ>�CN��߇i�h�F2n����Eu���n��Y�,�~B\�
.T݄����C�H��d��%�b@�>K�*?�`:y6q�9 -� ðX~[��偏g���9��݆������ni�E��-��g�\g�Y�)� ����1��ك|4#ZT}[\�f�����L�E�O}M}�r>�� I3�C8��Ͳ�(q�RX��e���x�c���!+���)wXU#�"�f�eyp�H �fk^������*��% �<qJ��o�ގ%`��>��J�-���e uB�[�y0Z�Ti&�5������72��)7K�(j�IF&����dg���	=����s�n�>��ΘףH�"E�)R�H�"E�)R�H�"E�)R�H��K�nR	  � 