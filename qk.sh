#!/bin/sh
# This script was generated using Makeself 2.5.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3273216461"
MD5="01bfe9b3d10b63b967959c78a861cc5e"
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
targetdir="tmp.jdXfndsoJh"
filesizes="48871"
totalsize="48871"
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
	echo Date of packaging: Tue Apr 22 11:05:27 CST 2025
	echo Built with Makeself version 2.5.0
	echo Build command was: "/usr/bin/makeself \\
    \"--notemp\" \\
    \"/tmp/tmp.jdXfndsoJh\" \\
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
	echo archdirname=\"tmp.jdXfndsoJh\"
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
� wh��x��.
G����`	���q�5�	Ĉ�,������ݝ��kpw��QU�g������?����{x��3ݳg��!5J�z�˻{�n^�ãl������§��OUT�FTA�Y�tA%E��6��%���M�����w������7�׿����yloSՆ	G��?���My�:�Ǯ�����a1���eLݠ_?4���������L�������>?U�E���n8g�ÎGv1� ���3^�qlg�W�[�4����t��P�z^�Nn9���Y�rG֌�m
�dr�Pڡ�qu��9vy0��=���C!��=�{�f������sfW=�Kǣ�3;��ظ��q4ڒ�ah�L����]=u��)O[����%6P��X�۹���k�Fm\3U�`_��C�5�6zX޷G��v�e���囥��э�"�U��9��D��R#��nt̐���o5�
�:ⵝ��6Ylr�ؤ�q��)j�/z}����5%c��cTB/�^�5O��/��E{ݒ�ޒ�N�6����l�ioN��A.�iC��d�U�{f�IO��OK;�95%:߽�r�W��辪���;��[qo�1.�G��W<����0��v9��%_rsa��!�#n�U����B66Gm.em�#o��ي�<)ٺ\q�l���wh�b5m��<�*͘�O2��v�yŵ᫼ޮ�Ь��7.8Z�/͸bh|���krxU,±`!�ļ�No�q۾�M���.�yWܻ=�����}v��km[�n0���� C u
��h�+<�@��q93�'����u��˟6]B�c����Tc���3�Չ�ș�y�eTZpHl�MhLl��PKP���7;�m��S?OLB|�3�Gj[.:��KP����GE�d��[#<.W�
+##�����4'�d�J�����ݥg���DE�x�k[@�"��Q���c����a��u��֨ y�N�'L�-*β���f��ζj���x}��.��c�Ԍ�
i�9"4�̀�]"�8�9�2y��b{{ۏy��Ƭ�˙�&����v�C�b��6]����:��Ym�\vx��&��S2���n������K.��#{fw�Xt|A�lv�
�;-,5εʸٻ�NN�|y3W8:ϱ�K�ߝ�W�9dZz'o���2�f�n|������\��yf�B?�Tϛ�5C�"�ul��e�h#�]k��}����^˛����th�h1>[;K���ع�1Yع^YٹA.#�9�q�ٹi92��K�rn1��7o��Y���{l�<���7�Q��h�36�e)`G�-�X�6�?��K��~����3^�����7�.�_�A��}���������w)Z�c_<����:���{r�z̞�d���	�'�����1�O&X�� |2�z���c�ǎ츳�؉7�;������X�ga�n���8��8;����z���y�
�o=��o=��o=�	�o=��o=��o���h�v�K�Z8>i%x�z���ߎC;���q�ߎ�v\��㪿k�{�v\��"����8�oǙ~;�Y��㏿�����oǷ~;��˱��n�َ~I���n��W�+�K��͘6i�7���r):փq�n;������9>��t��å�vǥ(���Ӹ~\�.g?��^��{Y�o�g{?��~g��2nB7pL����g�Tev;�ɕm�X�F9vפ��Y����6R��HKK5������l;����Oz_�?Z�;��k{���A��Ȍ���A8h�u�c����U������dU�;���h|Y�8���vd�bxq�c�ބ���u8���?5)�_�o�_���'�_�����ߖ���u��'�9���O�gFf<g܏O���A���3��>�ٞq��j|����q�\�vZ;�����qx� xD.W��}�Ķ�o��ڌ��������|�U۱wsV��@�����Z78��H����eli������?������e|����ڤ�Sm��/�ޖ�ܚ�֗[�&��Mn�_n���Y�I�r��=4�j������fG�P��}%�K:ξ�����61�-�s���y���lN�:j��`��%�a��~���L>c��Kƾ�K��t$�򷴴a{{;o5��d,,�a�����3���Ƹ��7���ᰰ48:�G���3��L���+iX?�t���o�A��6i��8�Ow�s��gy��(=u�8z`c%m��'���W6�H|���_�Ҏ���~I	��ed=�����M�7��dX����|_'\�;�g�k�_e��*��}���E�v���G��:�1�*i���7�Rr���������3I���U�GR��kv��+ʸS������*�ùb?XOOf猯^�G�S������_�!_�����)��/g;}aCt�%�b��$�c�W����'÷A��R*gO��^>�_�~�ٝ����q��r�_���'SaNm�֦����w�M�Uu)���{�+��]0�L����.�����hc��	U�������Ҙ���v�!�϶`w�	~��˰��F�%<��԰}����s����s+�hf�e�T�iL���4Y˦I��c�ܱI�itI�L8BW>�t�o<���BS�m���d}�Q������Υ�5�J��i��:��B�e�v��Lj]
�w7:w��c`i<��X���ǚ�/�uLZ5g"3���f}s�w`t�7vP�@�,��q�'?�p�3�k\I��*�L{<CϜ�ι�\t�a_��(G纳sy�܏fx�C�sO�\�/�s�鹪q�v:�αU��~q�#[�勌SOj���ī�Ro�3����Mov�N��"�UF/'�u��f.��a�R�!K�Ip�I�ގm+l\���ZǭO	z�/п�J�v[���3}��lW#�ԓ�v�_��5���w�s5��\v����)��ӝ�A�J}��;A=�ٸn;��b��r�Œf����0�cOq��N͂/~�x�+�c3.���v���m�>j�-�Ҍ��vl|��\��3.x��蓌Ma�U�ì��e����-��S��o��Z�n�����#�g��d�3)�m�Z�a�=�!��1c�����xo�?ܠ%���B�
{�$���(�_�<��߶���~^M��s��v5�l; c��C"��|O>���{~x���K�b��ok<��i%ߝ�v����#6�nI�pt��g29�v���U�4g��5��!������vdc��k���D�{{�.q�#����?���3����ƀ��~kH8㻜��O��_߁4z���R�6�h���h�j�a_e,kN�������M���u���6����m��F��l���xе�O����̒jLˡ���p��;[�^%#z�Tɐ`)l�麡���	��h�
	����v��N�����=�KXzf��eS9*!"�j��/o_����:�;�����J9�rGV������r(��_ٙ!�S�z;n�;!�����������h'��t�� �Ӓ�)��	_�V����	�g��6�25��4�˞���\�gqpg�����z���R�Z��J�+�����А��\kg�W�%sO�A6�
T(#�pk��E����^�6V��W_�}���
�n�\��`����z�]ͬ����������+�O��r����'��|_������=��[��qn��,c�kΨ[jePѶ����4(⋭�k[KQ�u��R��e�V������6����>e8�(��o����%��+���<:լ3�>q�κF�ϳ�1t�4�e��wr�缜V�-���>���i�J����g~�u�,Hǎ�Y�>����~���ϴh���<��i|�����J�;�qOjhf~������;�]��?�?rѱ}���s���g�_���>�~{~�������_��O:I�Y���ұ}�����',U�EP�ƻ:}6��N�C���s}Σϵ���>����|�=��i<��B�}V����ى>c�sP����v����{�����ͶG
���޻1w~d3�մ��8L�8�iڨCm3����Y�K�~Y|缠wR��i���4?�uXZ���6E=�9*:S��_#k�>���>!k�<�<b��"�۫���v����/��}${ʢL�o�p�ϩ�#��W�W*��e���Ȧ���W9U��ŏn���q y��?��\~���kǗ/t�ޏ�k������_=������)1����V���%.ܜ�?˷���ʲ���f�~�o�}e�*��;c'wr��f���I�J���y&�|�/yN�������J�]e��w�L]�g��s�[f�ݨXW���Vd�a�e���o���B�y��:��^]��;�h:uM�ӧ��5�+�7ǃ6�m�>�Ol:o�׉�f�Ϛ�}��s�e{�<���4簚�;>�Y7,iE�%u�n�=q`���k�}�[ԹV�SJynyӤ����l��E/V������>��.�"�7ʺ���~��<�c��x�'˷\T�`��y�-;+�ظZ�;L�\{����_��gs��g�z�an��/�_�~Ʀ���s���6�|���<F�����ơ��:^��-�:��<*���3A�jwj>�ؓ9���Is��~ֶk����ܷ\q�¾�k:��`��U�ٜNK���}��;��u��a��&���S���O*y�x�i�����ow��/���K�D_��]܇�+wݔ�~v�/�[�-q7�R��ٯ����.����K�lm_�ۗ��o��/����2-�ť�{5q���̝����=����_�I��di2i㚤�6�TJ�Y��s�¼�M}�^���v_#�
�S���+�
��gV
x�-�����>D�d5b�ŷ�MJ�{!{~y����|ꔂ-.��;ey�aR�Ž*/����n]FH��L��i�g��������״�\7��ݾߠ68Pwv~eKƊ���機0���;o�_p��dd��������^���fǧ3��۔/�W��_�UmA�ɷέ	r�W�}W��'m���x�<x�3�Mh�Z�8<g��#"��@iQ�1�*�[U*%��&I-�
�~�اw����r�����V��z�C?/}�Tk�:k�*�-�Ԥs���W��l�a����fe�pg���~�:�Ƚ2W��}�Om~�eV�i�y}�,��s��U�}��W�l�g�/]��3"[��ڗ4�B�>�W�Z���!]�W*�b��9�ond9��_Z���&�:5��y����*�#d���w�rv�d�ݧ��6�]���,��vz��g����o-:�����7w�Hk�7v/��ĽvVjQ?baj��~�zT�~�yo��+��K�8)�l颷�U�×�y��������:���7S��L�ۇ|:�J��,3�_~C�_7��V╼#SŲ��-����2'�;]ݰfghbL_ۮ�Z-��ʑ��j�w��O��:��Ωs����l�v�.�eܪЬ�z������W�!��z������^Z|�\=�p;*�&�%c��j����#}��jv�H���۟���g��e�v�S<C����G�Mn�)��^�1��S�_Wݑ|!���AS�9|�tv@\����������W˽kVXr�+S���=?帓�x���z^-7�6�Z�ol��Ķ6�W�1`���^fu�V_ƭZ=�6��z�[�Hӻ#Sf;�7�����C���W�m�s�k����EZ���_~ܞ���݁L�\ߵ٣_L+cs�H���-�ʭ��{�s�>�vG2u�P��R���R�������u�%b��4���c����ｧZГv�Mq�彭]�e�O^w�{���5��kT=6����#���ޝ^I;s�h{oK��Y��{���B˰�w�is�ҹ
�3|�q���i�;[��]U�v�_�� �I+���N�_�t1l~R�K��[�
	X0-4dC���k+=�pb�����J�\���O/Eϭ�w�+���I�1��;��/�~���=��X�M�
����]�����ݽ�˧9�D]��lgD�>c:x?�����:�3uw:��烼>�i����?��>�N�	��Gy�xU\4�f׿wu�����E���l�ϱ�K��/��ߙ��F�Ֆ^n]�p���G7�,�V.�ot�yru��vm6��2qe�{aR�qB���#�A��'vO�������[�6;(U�0t���͌£��8SnG��M/�?�}ŪS����������*�?u��o��z�]O���c�'��Fm���1B��G�]��c���}\�ި#>w߶@Ńُ~[q��z�}���ut�7�?Y↤nj�Wge���	uC3-���Ŏs�ە�������;�i�mn���)HZ~\�z���$�Y�2�����/?�u�^���|E+�k���\����2��2�:e�V{�/�ۊ�\��+8�҂Y�����8�[�K���Tw���ǥm�4ݗ�pД��#�'��Y��©����;-ť��[y'Upz��%C����s�0:O���M�3$i^�������pL��%up]yR�C���~H['�<��7"�՗��
6�_�jka�����}�4{ʰc�|&n��㻿{�YK*��٭^u�����r��Lï̜0�̥=���Z�"ya����=���v6K���~{V�M�񍩷�\���˫w�bUª]�9�J��g��5���G��VO~Ye{�-%��Op2c��%�d��\mih��,�ˌ��y��Yc&_K,޺�G�#��Lְ���?�=r�dǑ�1`����׽���^�[�ĕ��FT?]�⥥���I��V9[�`A�&/2Nn�qC���O�q�7{m�|ѧ�������JQϫg�]j�pA��ϟd-���~��3���Z�XV�^��S�V��{e]�j#qV�1�|rx5YR���O뮈�#��<��~��s�W�[2�V�h�<ݟ�ȵ�Y�%�#�ꑣ���v�p����u��y\�Z�-5�K:\��?�e��~����1�s'��^��R����n������J�K>�![�L;���y1�m��[.dt{�|�9f����U"&��w�W���F��_�01��>_��?]�{���{�������Yl�u�f\w���}�۽�}��ŝ�
�N~X���<S�>��ky���b6��Ō�ɮ#/u(�����M��\��{�>�/�*��ەU�5j�8a����gq��i]��rµ�nk��=��d���ʗ�;a��'���H�͙�޾WȘ�i�i_9ε���գO3n��λd�|�إ:/o����㗼��jp�����߯~_!��\����r�����������{���SZ땷�kTm�����T?�f�1�+�W�oS��,�͒�j�����䋻�v���'���/��O��ܿ#��{�rrZb���ڮ����J��S|�K�Pv�;������ӵ)�o�F%��<�����9F�.�;t��M�����v�%�Ǉ��9x�
��?��f����O.��b�w��U6��͋�ƮxQ{u��{�e�B+�xw��r|�3�}ڜI�����R�����E�ܸ�렛�]������sew����麯�����L��Ꟙ;�>���R�ʄ�n�q���R���lv�����~���o�~SҐ���7��t���?�V��h�g��׵��:�m���z�����9�6�ʳ��>�k��ɑR%��UR���y։�e.��[a�G�b_�*��X�u��#+��j��de3��wn�~��V���d����G�g����%h�+�I�+5
]vgk׊�ĵ�]�攊uр�*8'd�0ҳ��3%�mڵ0g|�^=?����'�K�k����n�=�4ؙQ�S�ڠJ���(Y��Q�W��T�ӻ����k-��p}�Im�>-�cА�J�6<�m4�e���Ӆ���Vh�wmp��7Z��[��H�U%3�
�*��m��]|?{��wW:���fg^�2�������NX|�/h���O9_x��QJ��5.�E��y����9�r��톼k�3O�q+��_���׀���>:�×<I�֝��lD�b�Bz���~W��G[�3�No<u��I��M�s{�/٭|�K��������K�����8#��A^m߼�0�g@�q`�rc�fn��n��]��y��]nf�X+sp��%��|�%s�zI7��/N,����<�%V�6Y;�of�C��_lV��37���s<ْq�/�<�o߾ω��>d�����:��%-�l������\9��O�;7�hu�ݢs+���[T��u�7�)w[y^Z������V�����]�-G���2�̽2�>�<|����6����{eP�i�_M_P���)g�.G�n��v;�_�yv����v��pP~�����/.�?�*�[��[|��0/`Ń�:�?ߗg�V���ǆi{�|��W�%N�H�0�ř��7-s�m�Њu��"�N�����u/�_|e��m�~8�K�����xd�m���{�O���B�����=�q��'e}q�ӱ��?{��{p����Q�q*f]�Wv�}�O� =���¥s�k���g�_��nvѳ�:,>��֥l�׷�T�ƫ�������\ĄR�n|x\��L��[M�U�g���z)�[�_j�RhDۓ�V�ݻ��Ac�ozx�]E�����{�̗�]we���V���6r���
�2�2F��V/<��u܌j���=�o�c������k���^˼8�䘺^�)#�u;��;�ns`�A�֯�O����=��:�ƍ�+���Y*T~0d��Ԥ	e���<jX�e>ZF߻�x�r_�j��3`w�'�^�V���[U��r�brjm�J�Wk���~n�F�4�y�޵���ۄ�K����In�=�7M�ܧU�k����N�s�v���{r�{�T�ե�����:<giת�[SܮhR�Km��V��8��.�v\]l��M�=���~j`�Iyc�|y�wD�}_|_<��m�׃���f�$ܾl�G�m��&<���ˎi	vX?����#�UY���҅����C��5�~8aA�q�΍�[���-,���G��\t��+��d|u��Z���|2���ȱ+{?���~6��_�ſK;���x���=h4�|�{~�
^�����m��o�Q������^m�l���j�3\wߘҮ�G;��=;7v�L��r�F�s-޾�raa���KK{������o��߬Q�k*�:���?$a��5����5Y�e�>��O��8����j�GJ�ʚTfc���#~N�.�i��gն'��M)��S���86�_y�p߆�����VL���]JP
6���}˶��*���ýb�ф&�^iB�j7|˶��2c�}�	�
���e�]�,_�`Œ���[G�svvk�OY��z�~���;*?�6�P㋃�u8�t������}T%zT�q)[J������K[�~_�q�g�VR�/�b���9�����mu���	k/�\Y%��.��]�^�Α����V�I�z7z/9v���2ߋv��*K�|�·ϹX"���s�r��>�J���^M.3��{����9<�`��=����UNE�ԴT��j�Xc�ó�ܦo����e�}O������T�5�5���������F�ۧ����p�_�}���u{N枎���8�*�	�\P�����l��#ֽj�|�n�
':�,Iq�^Y��+��R���=:�=��>���ߣwwMy��,b_㯹��=|��Q����^����F�n�{W�o՘��������&Կ�+�3=r������mzt�sz��/פ�EF���y79�&�-�]mV�N=Mo֤E�'O�E�/]��ӒQM��+t]���vN�%�.ݓ0~����3֗8�p�w�nzv�s'Ѷ���K���8� kjy��jϦ=�*6���\��ϔ~1�G��?z�_f�RM}̈�n��[��V�������.���rϱftr��*���z�g~��)Owx7�7��ٕ�������S6���9/�~�z����}?[���W�R�� ���>���ݰ#ǺԆ��Ɵ��y�m�M�+�Z_faN�V5��lw|��<����0`Ғ���ܻ��Z7������s%�$��ux��u϶8fi���~�?,w^�!C����%��~h>��k~Ȼ���Kg��js�k�uG��t�]n��۾=ɓ)��J��O�i�i�@�/��	;�[j����e�������cɐRwʮ����\̫$���:�q}J���_��[w��ǭe'����~��QQ='^q7%���ܵ�ݬ�l˔��3;/��i�C���ˇ��:��ap���+�>]^y:�w���ߦ8o����R��'���L�y�p�״63�Isx6rG������w��u�m#'�V24&1k�	�����jզN�V���/�|Q��۾.rɲ�[ʂ�Ӌ5��{A�pO����ݩ�����K۔8�]�i� �>�iӽˬi[��Ƀ�����#sài�Ol��r���++�v/y �]�p�9/�n���%��_7e�T�c�'������F����ͧf�?�s����^٦FU˻2���C�;�<Q���ϡNC__�vV�B����2��ˊ/yJ��_�p��W�Uwr�{�>�����Vu|�8O�-�W�0{B���o�\~qb���z�V9�n��!/��O�ݻ��'�C�5P����3���OU� ����m����\��f��<�Z��6�?9�Q����zt�rd�����Vf[��W����ޞ�5�T�1KW��z����2g��>�޽���\z�~Ƙ:�iq�j�>f�6�k�ѵ�����t]�Bk�w��d`x�n�?��Y�q�����+��pJM�G=3��-�WA}��uI�2N�ig��^s{t���ȥ�9nytis��\�Ο\��E�|�[7\�zk���O�Mt9t�@�&cw��4�I��5b'�5����z�zIA��P�aD�ҡm�8d������u�Wh��L�։�K�l�S�͡Z;�z0�5��d��5�u^�Uzt�y���zt?9�Y��6�������3W����nO�7�>�h�CǺ�\�ඨb�9�V��|����7_8��ǋ=���8|�����l����p�z�C��N�u��oʶ�*ϊ:�ݬ�}{�/�oq�Sa�',W_d輧���rﾘ[�#��|&{��:��q�����uᗲ�ٴ`E�'����S�d*�>�v�aes��"��Z�taJ�G%�>�nɏ��^�v�i2�o�CY*�8]�Pq��q32�~�|e�;g�yl1��9ꝨS?��m�|��,86�{ՀVv翸���dJ�n����юu={���R󼒽`ΒG�t^q�����9���Ϝ���~]����_�nkZ^<����n�z4�|�Zmq��'~�sz���C��+J��R�������u�ڦ��,�����ى��74�Y�`�&��4�z%�q�'
���3��F�������ʰ�Q'�X��ӫ2ڼY/���^3����wx�����f}�7�em\}����p�ov�r'��{�Zr�ܘ!�b7Gzn{0�h��s���+�^<{�к�w��=�6|��IU��ܔaȘQ�K��y�=!�܂gr'�������q�����䲝cӪޚ�_�j�ync��b�/>ɇJ��xӽG�O�+�ö[/ɱ⵷>akb�����������rzm^��]�C�[F�k���ٯڸ��[i��^�ȃ1���)#xλ���~pj7�c�|�d.;*����&�z�����19�ZWo���}�/zy���~�/��7�L��o:���ϵ�Y;�����(�y���C=�귷�һ�?ҸyD�>_�l�T����ó�̮ڹ|�zN�lZ��v� Ca����~g
����f�S�J�K���Բ^����h⻽��F�jT�����ҽD�y�-r���y�ۺ�ί�9�qZ�5�/���>��h��G��/��,ө�yb�U��s�aH�;g�%f���^��)^/��Y�9ۇ�!a��f��"n��9�_jw�ψ����۷~�K��>��Nx��)��ѓ�x_�/������
��}�rvϜ2�Ȯ%./zo���m�����t-ߎ��n�\Z����o�\�ŏ���x��@ۺÞ��2~���k��������:���s,.8SޛG�7�-.hTئv�U�D�<�N��rtI{Xyo�i�>m[���m�E;�.���R�yK�}Zw�m۹�>v�Ф���N{+4S�ߎ:}������l8ܵ�������7����Y
��8��Li~�\9�U��l���{ϕ��*��cK7�oٝ'���V��^�9���|�vO�Xe��RO��:����wq>]��*��]���^�8xݥ_�D���f��ٻ�Ų�/����~��,z��,s�:��_iQx��[>��UZ�J���T(��Cĥ�9��){��������䀟�ԣ���:��I�8���?�T�P3��L�w%.����*��}�+i�_�^ZC�?`�ˣbuŚ��dy��B�g���{��[YqI��[��g�:�f���vC��l�eB��.�c.�uW�ЦWRN����롔��ˇͯ6fY�S�۬{��ɣ}�䢕�/�xI�'.��=����!k_f͜�¥�����N�U�q���.e�R#w��?�:��<�Z�Fɫg�]lwJ{[�j�c��Zi\�~�n-mҭգE���8��sR���KǍ�+b����;���{�p��崨�hߌm����i�ܭ�*�>�{x@B�:�:^Ou�;�u��ò���������c�)��B���-���K���~8)^�:n��x���zV���u�ݩмT��jR�Q�k���W˚u��;J�B߾ɕ�w_�Z�t*Z�ܰ�-r^���E�]��v-�rݢۋn}��aJ�9crV\x�;e}���J��nanU����������.����b����Ug�k�¡�������_������cW_~Yޣs�r�Ϧf������X��=�޺�����*޵�em���2̵;��C�3�#�,��7��(�B	���eH~V�C��]'N��">��u��j�g~�[9������sW��}��������6ە���۾��S{�k�T���_?(_�F����L��kw�}-6��������ӗ.��I�_��;:�}���^�zT�ۊѷ.&	��~Sbh۹}�V'NZ��Z;O\�B�i'N�>5��%��=Ѱ�y����Z˿Ƙ	�w<k��ˁu�.���j�Q�WT�U�{\��5%�N=�;/����M�3�&w��Ѿ_u���K+w��e�35�r���&t��pT��v9]�$�����jϏ�Φ�8p�F�g/�6��5s�����0�ÔX�,
�+��[��)=�Z�~����q}�uj�:�;���w���F�|�5�o��v�
�Ҽꛌ����d;����v7�.Z��*�G�B}->�Δ#=t��+N]�D�i}Z���8dة���+l�l��:i�85p��5�{��U�Å&+�W�n�ܿ�ܢ����ǅ6|��\7�Rǿ|J�:��^�)�/[U����-�����~t�z�˵S�&��v&�����6��|Ưd�ͫ�NZ�?��sW�Ys���7����nN�ԴS�,{:�c`�_��� ��V�R�S��'ʌ����@��Ӟ6�=��d׶�+�ޢ�sݕ�g����:�G�1�7=m��P�S/{g�6�z��?�a�1���W޳��Ƕ����������ٲt��~�~nn`���nQg���:�ۗ��=��zw��|j�ۣ����������t���wZ������تw�t>3}�Y5Jon)�i���`����B�c6�^������M�k�h�?�g����n	��D�'^,�Y�зz�ӎv�zr�@���+%Ny�1C�M�>�ױAL��-�(g���t����/�R'�ȗ�gB�󧽧�=�ٷ�ɵZ��sg��i��1��ż��w{�9"��d��ɍ�=M�6�����[O=�>K��	��]�4P\����.���^�j��H�����W��\��G��U���5�#�	��3�e�,|��z�U�W��[�kc�k�;��Zux��z�����[����>tO>����K�/����ĉ\*79W�Y��q[�ǜ���߲�_XCq��kÚ�ھ|z��GZ�r�~��o�V݉��>K�:����rK6��9j��yܸ��Á��}s8�N���X��5m���0����O?�����������$v+����=#.���j�|ۭ�\k���Mu�XmU��Y+�L���H��䓗fnڛwRb��.ڬ-ޖJ(9j�-Ǧ�
����ɮ�����~�%�ʱ���G5�D��Zg��!e���>&62v���C�U�;�lٲKg������3 �i��_TO�*W�^]^�P�%��sn�Yv�T>�sq�n����r���E��2�2�H���s�pn��r`�-�Ŵ�S����׻�8�͆�C�\hXjuh�b?l;��r~�ӱC��X�Zw�Pru�Um����6�[�����8�f�u�n�����c�6��?lL�s��,����;�:�_z[���l���k��_���nوFZ�u=���
�U|y#v�˜����V|ɦm��%��ʞ96��B�e�֗Hl��g�˩Kn�vf�����U�6���E7�6ۘ�up�K��S�VQc܂bmm3E.���pA&�o]��{�.2����Q��Fd�.��[���_Gv~�����Ԩ�2�a5_e�����ľ�a-o���[��g��L5.i�3���|�������Yy��eW�n��wx1�Y�����`��mF9�����gǵ��cԣ��G�?7�窖i�'<�,�y��������ޫt���%�&>*>�����a'�:�]�zZz�;���e�ƝEG=�|G�9�m��r9�o6�r��/WƮ�>��x~��SzB���-�νY;~H��v���;4��}������ק����{��;|xz�����~�o.Y�����y����_W�z9ut\׵d����Vl�>}�@�9fs<~U��9������E�������3�y�OY�ؾ���������/���k����s��<�+27k���F��U~������m�ޕ��aR��?B��/�!���#Y�ꌋ�/^��ܝ�����q�o�0�@H����(���}O��F<�\r��2��gwmՅ>�L�\����;~|6��U۞,ٵ���s��'s��uq���Z/�ܷD��+=�k|��ށ�3�\�~:ߏ���Gv�_{G��R�c34(�f:k��g��UG��P}g��-2�X{��u}a��wl6{����A�z�u}|ȸ���ü�ל�9ߺ�����ϭ:�f�*�/<\�y�ݽ�c����Ӳ����O��C�m��v�����I�������T��������Z��'K�~���������V��MS.��RS�ވ���ef���|2>��^3;u^~�}���ߵKW�X�>�{�b�#��4���^�{J��ۘ�Fw�}?�>x2�N�ޕ�N5*��%£]��߅���hJ%�F�F�5�v�����Y��UC�k�8Z��>H�=��^�ʾ�}=�@������NW�9�Ҙ�c/D��&MZ�{oLlb߹��/e}^oK����n�&UO���*:�ڥ_J��J�:�V�ר��n���9g曳��?>�訚ss�ݥe�U����*7���.��Q��ڭl�;�o֙q{G���,������*�3S��>Ӳ5����Ș�%�.�����Tyo���~|�,��[�8\7��6�kf��,�V�~�����C���K9����~����/�y���7[p�3�϶i�e��sc�L>������ٯ|uhܼ�-\Xd��?�^p�܊G��QϚk�]zuv�%��������	�����<V>���ǉ�y?���*����/ԯ����C׍��j����ڬc��b�#��n��qkt��̔ǫRs�ifw����K~.3�,�>������5�"��I?�Jj�ul�x���Ĩ;��v�L�s�m���;��������y��w/8eE��Z�������+�V�9��q��k�s���?ux�]��%����ky��#�k�;9��O�g���r�HΞ+��;�b�M�>���̾d�!ku���6!�7�����h���b��eB����gګ�?�:�~z|��WS�?�_3񹝰"�ث/*�N�����j�\�w�Ē�M�\m�}�E��ۮ�+���<������tś��N�)�&�s�7w��mK�j�tB���U\V^�2��������,�[U�=D�Vmbl�!����v�=n�����[�k^�{��X�V��V�j0��Z�RݸF1_�����b~��&�.��V޷��\��m{쩐���ϖN򴱬�wz�ϝ�_'���-0���~�NO\��~h5��m��o6�M�ٗ�6�:���ݤg8p)iMޔ���W��6�k��ܪ=j����W��ǂ{�}ᾹO�x�CʌF_'��ko�lg��ݟ���:��M�t�.���j3\<ܾZ�|�_zmG�f��|w�u:�uz���g�n�}���K����;��Q0oHR�~��D,iv���g/9S�����<�שԼ������F}����b�|������������ԝ��i����e����E��w�^��ۂ{���Xi��+U�4=����������6^t�`��n���(zu���?f<x�Ӹ�{�z��n�����Ng��f�y���k���Gn�Rgl�Ɏ.��W��Z�(y��~~{�~�x��iE4n�aZ�U��O��2dk�R5�8��9ֽr�<�E�8D�u�L���P����gۋݷŭO�~Y���]$�{��#��93m�s���>���Բcd�&]�n���sק��t�U�Ҫ��n���������䛱��'g
4�z�Ă�v�ls��[�?v1�ɜ�^,t�׌���x�m���/GWN�V�M��b�߮��+�W�YgUŊ����]{�4����Y��ݼ�'-�g��AWgW/V�o�MK�<mf��acr�����`�:�%◌hP�H��'}�t���y\�s��>\��u�k�]�3f}��D�8n�o�*6J,��E�~{�i7�߳�'\����ŝ{��ߘ2u�d:�o�▫�O�����U픯���uG�ys.������觜��M㦩�v66-�5i�g��%$���,^��%�JKm̮�o��@r�ė߳_�����މ_2�r�Q�/�����dHv�Kܛ��#)�_��q��e��ꗶwd��'��\�Ӷ	������g�g;�a#��?s�K;<2�_ڑQyl�'8[�(���'�|�����{��j�w�G����?O|��2�2ˢJ����Kȗ�/q��m�đ�$���6��Ҳ�K��Ҟ%��؆Qxm��q�MR�v��܎����7m�<���o�~�W��u��Z�LH���MǮv]m[�d�:0�ke��٦Dݨ�芖�a�q�P�2���-$��3<>�biѸ�%�WHPB|`g�
�:�S��;!��W\�WTH���]pE�^�$K��ޱ�]��-�5=,b�
��$H�y��!��^��KSvU��iH\Hl���^�<>v�3Z��/eK0]�x�O�������|0��Vr�/���ڞhڸU��|��uu�i۴cW��i]��;�%�*�ڸm�����l��������c��6~��%��%�+��5cۮ���>i;�0����mt L��Yll�;b��q���z6�_�&�j��/�_�ѱe�g�~N�I-;�}KK[YyP�s�=3��%>S��ʶ=��r������=i�\�z|���"���g��h��ҧ���G~���|�v�ƵM��m��-�K�j�1�s]cޯ���D���Y>�����������i.z��������x�a{{g��v;[W����M韶�fy��li�Uz�}����M��U�<������n�Q1�z���_;&�q<]ʱ|��~i/�^�{b�����{��,��k~/n�g�ϧMǀ-/.�n�Ʊ�{��Cv���Ӯ�l�)�����k������i^��:E��Jtv�W���^�J;�t��]���mw�HK�h�t;�b��߆�
؝9Z��Nm��l�{�Ӌ=���̣��������οg��=���\������f���{9sIxfg[�g;O(�#��&=��'�y�R/-�y����.��<�ٗ���>]���k��L���h��Ϟ�k�#o�>-�]���O�'[\���>O�s�]�֢�\�>�P�u{����]�?�Ir�kr�\�	�w?�J���{%d��o#l*�,ð�	��v�Të��o���U���߳�-y��"�6/�?��J�gy6G�j�/����G��~���n)�h߻[Ҏ�L�/�m0���a����ic�yU���*�	.��pLm���ױօ�n��|:�kt֤�[��^���y;{�v�#
7;��Ͼsύi�Kto����O�����׆�Y����#�	���������ۮ|���.�F�����n���=9J�\�q}v���َ����E��-�5x����0�.���-����y�ʽ�V�pC�Y�"o�Kw'���K��r��w���o���vq�^~��_��'��_����1�b��m��]�i�3T㗺�ǁ��]�*~z�;��˰���||�ȡ���K���,�m�V{��E��]��ȥ��Y��_�����U����#��	�ݵB��K{�ڭ?_��T�����]��p�ͯ�Uz�t`i��}�����q�ƌ]��|�"!��|�eB�#K\���=�eۖ��[�9ٶyϞf�cv��x���͑,���Z�fN��7��+v���6��T.�)�P�9�����̍�}����e��u��aư8纪�O�<�Qi�=�gh��z�&q�w�ݵ;�51x��L��:����P���3?�ֵoeI}��n��?������Z�!����Ԭ��=��Z�|:��5l���v��o��>�r�i��35��z��e��)�t5K�֫6�$�E5^{��P���oY��$O�Y���	�vU^�cٙ�>y�~ۇ'�[=�[d�C,��FkN��[���6���P�����穕��S��ON?�t�����-o�7Sϵ?��s�ه&�w��o��f��x��۝:�k{f�}H��{�E���<��s��BB�����]�t�d����=+�?�����,�^i��|������o�z��vw�~ ^/�tľF�,��܍ɱ}�؂�6����X�z|�%ٯ�o�j�Kޟ���;�+�)�e������h�rslV�J�����Ȕ�c�Oe&��z=,�M��U��Kȱ����;�)�`�
Y\FW_us���/�
�G��Y(,���OG� �3�-���˲&_+X|�E����,���nj5�,�y7>�,1�J|��3��׹�����ʂW�\���̧k{�4H-9ۧY��=;]��#�J�7��W��sOHm�l�S���?m\6���)9���}԰��r�Gd��}���_�O�=T-{�=z�oX;��qq���m2ݲ�}�gScs�Uq�w�ՂJ��םTϧq�n�3��>o�T�ܾ�$��m>(��a�s��Y~x�,-��1��P�!ݗ��q��y�^�*���+<lִe�!�:5��jp�,��&fvh本�����[���k��olڦZ��]�)����t8��u�Vu����pi�ar���Iۓ��uƯ��&f����#�WgpL�[��a�&�݋�P4��oQ���ۭv�=�M��ys,�Y�ѵvw�lټ�P�#mZ%8wٵv�g�xeˑv4O���>�w�)\��������.�9e���U���Aߊ��|��l�c����ž�z���
�=���;��խםJQ���ĳv���B�_�� �I���
6}_5����l]����h���K��٪FL.�h�y�[�9����.�����Vݷ�V {���}��>]��P���ۜG��X�g�l��[ݑe?c��m�L�76k��76~i��m�"|s���llU�n���4��iv��贴:5kV�����`e/[�SK������ Iɪx䱱����5Ժ�ؾם���8DE{u�J�����g�����s�
������>5�zV�bS0,�~�ȏ[��{G���th��Ǯ�k�}�£��������sw����a���Lv�^.�1.$(�W��K/ۇ���9��[H@Xpl֚��Yzo;�u���k�p��n�s�v���)}���7������v.W�u���ޡ����Z�KYs�;T+o�Pp}����K�j�����Jx?��j�
�F�;�*x��R���Ǵ��L;֎����Aɛ)�'��=MjVsm8�y����C�KY{���ϡ��}�;�ڟ����v����i{��1U��9D��tX���HG��=Cb����oV����>;:��6t_��i#�ը{5s%'W�j��rWl�O
�ۺ֡`��j%�_)fqu���<�\G����ew(��jfW�j��\i^v�N�u�~~4-�C�,�z���fM��E��tʛ�ڦj�O�g��8�N�8"bW�������]m|�����Mߏm^�ϖ�7S�bE�8xz��^l���]{�j������B:�ӷ�Œ�ʄl�m�Z��5��L�S͡xD�����Pd��j6�m�f�~��)�Z���['6ȳ'Z�﹯f[��v��;kǗ�Vv�M&�<��K
W*Ws��6l��0}	O����s��bC�]�U�5CK�H5��o�������w�����ԋ������+�gI�w�g]�����K�/��9<ʻs`\��sHPX��3���^��vb%Y��`�9M��!���k��G�>�����I����Z�`�f����xKBLp`|�ų7u�6ã�����t��w���g�*!><"�38��_�EG�~���3$..$*><0�o�=�Bb��CÃ�����mP`PX��'#���~.2���%���4���v*"��o�����v&"�sHD�?���E\\�?}�ۙhaTxT�@O�߾��%�Í�Cz�G�F�v6����
<㣣#~��^}<a�~;��h��`xq˓�R��?\=���$��-|���H1�K_�F���d�\�������nn�M}kUI7Gىf����vƓR��y�{(=���j�mZŭ�{L�`�.AAn��}�6����|��ب�7��>���L�F4j��7ё��Q�̇Ç=������&�y�u��&̡�I#�Z�hڼ�k�:�w�5����FS��5��4����N�P�-0*86:<X�<U/Qp�/�t_������}�xj^"�WҝW�󚛳�s������XE���rg7����E��͈UTA/��q�lmQ�R^�=�kk�bUQ� ��K�_��5*�F./W$~��(z	^"{��G�v?^�=u쬇)����D_6��?��(yك]����d��Cqxp8*�����[����/z�{u�;�t�I龖�k5��r����1(�U�}��o��ߪ^�;�������]�RG,������M�5;����{��a��cC�-�1��5[���O�o{4y��US-�Q��f1���b)�G��.�I��~�����B"B��C�:�F�U1:֜������y9��q�9���b������ߞUҳL76-�g����r����?�[��,�x���,��ƘZW�����T)K�_T��A����A�6%?�����f%�]-�g�~�k򫝣S�lH�3i~���~���`^�nIm.��{�������|����2ְ!Tc�ê��I\����*z{S�yu�����e�+�s$���������4�������������{��u��<�4=u͚��W������nޭ��	�_Y�V�?'�7�tx�9=��7fG%���MT���#$".�>7�֞%~]V��[?������r�Dv�a���~��g��x�g�F�����yʱW�>�8��q��DƇF�Ć0�#>��N�'�������	��3DY�w���%D�X�Y���o��<'y��2-���O�]�p���5��Xl��QR��Q=Y>:u����᧠6z���K�����ck��+%u�c�n��h������*^�c�x����/6���߸��U�6��T	��ە_�%�Z���Y�N��n�o��������w-u�~|�c����Z�p� �D�1:2 6$&�z�?o�z���s`|P��Bli���7j�u4��IȻ�H�T7���� xp'�j�?������i��ƨ�U��m�=�:��䑨���=g1�������r����	�bJ.��;&>�3+������գ�W̐��i��p���I�_5�Ѥ�(ߍ�)�v�Y��n#8����KGX�C�L�ᚶ̿�Z�WK������I����.Uإ����Km����t�F���_�t���տ�ja)�&A��3���٦;��[�q=�����6>����G��?J�t=H��۟�;�߼�����ǆ��\�e|����?<*$�KH�f�m̎
0L� ��Yi
���o�W��W/�H���u��������!��������_�hH5����%��?Ζ�e�2]W���t��GW���ߦ+��c�R��+q�ߦ+��c�R��+q��ߦ'���{2"�G��m�.���L8������e<������L�DР�?h�?��!��d��5� Y��0̷��w�B$���f��)����⁢����](y=ؾ��ؤ߮���ك�U"�)K�*�[����wr
�弳a[-������n�����X7gf�:�􊉎��PJ�tk��ap�/�4��R�|��+�`��>Mk�U1�������[6�"�rPקY�S5�6j�,�h_���U~]]�<��B��i^�:1�kaR:;�/ʿY�U�����E��%6<4�W�w}�f-<����2��3.!�r�Z��O��s������3�b����y!ҭˈ@\�q��Q1	Qݼ�J��Xc���p�;;AԳK�����P����],��D'��7�]%�R�f���o@�R��5�S=,%y���Q���e~��f��Q�?`22��S�?�?~T���l�v���G���_.�����?�߿Y����ӚM���	�_�JD����:��B,οL-cf�_���W�_^����g�4E�g��$�������E�����%�/c����,-Cbjآx	^r9K������ K����K����c{���	��uv�Ӱ��Nc�W��A��^`XxpB��/02<�R�+����â��0���3,�����W��֡Q�q�����G�g�?^ѽ[7/c��8�
uv6�0�h�%(�0���-�:X��ꀡޓ��+�����Y'w�R�W��Nn�EMw�������c����%�k]k/�J{c>��e��$�i�9Al/+�߂n��J{Q��K��ۓ�º�Ɠ$����D�%�E����K�q��^�U�QK�X��K2�4�$(����i����4�!�F��xi����=�9Y2^��[�߉��<Y����1���Gϲ�f��9�*��똸���U������k�s�2�\P�#%Q0��h�dk"�!C������!����oc\k��d�C֌k%�>�q��~/o*�5�ۋ�{Uƞ�T���z��x�����"�}d��3z��8�Y��}��z��øF`߱�3��Ƴ%�QR�=�v��1�TƧ`���~�ӻ� K�:���-v�l܇=����&������m����1AeY�������2�֯��D|W6k�;�~����}4��&� ������U��2���C�^lf��Fv6��ٚ�3���"@����c-�(	��$��d����Y�ؼb��~#�s^��C�/d�oX�=$M���{���X?Q(:�x	V�(Ip����-l��lAK��\amV�W�����a��xW֗[��vA�O�{���^�3]��+��{���O%Z�lU�0��m<�}����CW� �'���/�6��z��*���6�ٽ�[�k{oE�w��&㘱��{g6��A�*�/�/{6ֺF}��Db낭S����k3S��C
��:�6J�>�J�b�^��)Ø� 	e��(�8�T	�mcm��c;X���f}/��[�=��s��`��й���%Z��A��D�}�֬
��[�>h��ƀ�{�!��o{v�L0~'�\2�Aa�5�&W$���{�=X���S6@��Z���(���L.�d�a	*lN�.���R&)	8A�I ٘��+29�C�q0�*��h?�7�6�E�&g4�'l|����a���WM��*����R��
��2�q]�ƨ���n3���	��A�I�����z6g�L�q�u�65�\�M�(�yͮUp|a$�֪��;ºR����Hr�$k����	�-�#ln�����d�"�|QY��8�@��Ǝ�[�_�x� r��}&��Lu�7Џ��s��|x&Ϙy�sGT�@��y��"�]�����W05\G �hNØ��`�B��csR�����bkF��8%��*�]2�{l\@�kcxTD��F�ϳfU���Tt4I��j����t����ʖ��6�l�D�3�
�=��:�6lk7~'�X���9�L[vۡ�C'��:Ň�7�Y^�+���U/U�s}���2QcA).�cz�D[��5`T�N�Me��I6sD� hwf;/{u	%��w.vA՜�"�$��L���f��j_2�pL��h!L�s-4*&Eu�H au��I_e���4��)&4��L��vV���ɤ [�
�45�F���v��C���R���leZ	{��+{7���5&�H���S��N0�Pӓ��u�:j@��4ܵ`�Wi��Jp�0I�$�L��;�ĤhL������CZ����e�k�:~2��'3��uzG����h����$i��nPh��.)�����i��Lخ�ӻ�9�$)�U%��A:�݌�Ki'cmgm`.3�G�w9	�%ەt��Aq�0)�4Zv�6��D�5���Y`h(�Y"����U|�i�h�� ���4HG&��|T5��I`����e��ĵ8�۲��4HX�:�+6~����ڊ�ڄ�`����T��e�f5��U�K"h:h�0�*�7��	2kC����oAkǵìXL�fZ�'UFMY▂Ǭ�@k"vd�ݒV/�6��5����y-�E��?jA�-��m���pg��1kBB�kh����h�qkD��N�wb}�'��1&�$��a>���r��!A�d�,�<q��E�2�� 6���?6��SXwl��*���搆�M�>{��;�����K�U�"�����,U��� W�d�D}�Ɵ�����,=6�\?�O%��tܾt�4d�?@�u�Ü�AC+���aib;�˵F�o��%2\���~�VBm��)�4t�*j8`ݡ���6�d�C�֌D��9Y��)��L�b��,2�h%a�"��a��S��`M��� '����2��`AI�_l}2�4H�t�5��@�݂B����c����N���ڸ�ma|4��4��l�Úas�Y�읨l>J�/��&�Albr��1f�)|�P�=Q6�Q����s\G�	��L��q�NE��XG$�P��^(�5�֩��1�<3�>Q[��DM�n�G�Z�&������Z�l�.���oc���@����5:z~`N�(A�0O�
�,�V��6L{(�S�3�*��kG�j ����.��@����s�L�"���c�4SMA�#u,oքi����L��0�'���X�:�)"����V	{w	u>�C�~C�Y�}�]���ѻ��:�ी���LR���d5�R�}d�,�d��s�6*�O�=�S"����r�?���
�ƌ�7��S��K�߲�%��A�~  �C��bzh�*��RG���{x����0x�D���#�W"z�P���[����i�݃5*j�G1}�yx���Z�<�di�����a�л��q����>	�H��OqO�=��"���k�.��8�Ei���s����٤�ǃt:��=<"��p�~��܆q�����Pgt~�2��K�1����m����$�N&��d=�7�/�gR����RHW�P7���{�{ _�*����J8�0�U���}�IӬ��Ľj�c��N"O��}ͽnॖ�+���ǅ���GB�<�
zHa޳u)�>����ʲ���x�HWgkWA]�#[L63�k
=��I{��%���Ve8��*z���7[C�.�=�z�J>��"�	�A/UI�a.����#ox�ؽ�� o[0g��$�A7QGЋL�-z�E�= <���
���+�4��	��L�L���ɾ����3sQ����K������
m>еټ��OM��	4��y�q۔�a��L*�`�X��RP�D�M%��Z�*��Y�ރ����PpOf}��"�[v��1tK��$��@/GY/��K����k�7������)`�E��i�g����<x5�*�-�rl���Y@� �C$׏�r���v>���,�kN ? ��7��kh;��4��>v5[�Pfp�6�K�R�˨ Sq��}<Ͱ�S���� ����!@~��J�gl��Z���^���rNF���I���=B亩��*�-u�A&Y��܀�y�Y;T�2@ID=BE;O"��
d�OA_����2��2�����d&��|�ku ���2��L�(�Qg$]O����&�,���(��$��Hd��K��B!cn�h��-��+�[y���AT����c��(�3����rRur-*(?��e�z�f�Q`7@D���o�~�k����ȣ���OvӇ�,&]N�J�"lm�9 <���Tp�������&�A�I����I���!��#�
�Mmt�|S0w@W@;b���ЬQ�2���2����`��d����������O��h�Uqߧ�EyO�����"ܖ�$�+[��i-�l}�Ɏ�)J����~f�hK��GG���2��l�G�t���ƱA�*�\�HWb��G~h�%j�YX� �P(��kS�� �3׵�S��%�[�Gx�:&�%�=��B����ⷖ����!�=AG`k���
2��Ǡ���P�WP�A�u���?d}�G�+�|�p�٥�� Q #v0op@TM�h)�s�#Km���(�@�_�@�Y ��P��Ql/�ho[QAۀ��2�`��$�?
���v6���)e��@�D��*F�a�39�.
�B�ek�Fi�1��~F�i��R�Gp?� ktL���/�qf{)�m�Oq��� =��Pl���g;�B<�_}�@F�Ao%���P���9)��x1���-�l�Vd���K���M��	��`ͨ��>fr|h�6��(
�3"}Y �^C}l������PV����::�E��Ц�p��d�?����BAA�ve��}��`�͹>��u��D��@��H��ܣ .$c"�f�I����2UB�
P�S���1�k��/	z'�r��DA ݐ��2�iI�"> %�#�|.q�]!��6�N���j���g�ʤ���:,��e�) �@�=Q.f<��߲J6�/��*�&��I� ���-�Vu�n)����x��� �A��FR(^"b�|�\RH/A��E�i�P7h���~����_��(��ekE�9~m�"�0."鰊�����(u��8�pn �HC�D{�,r�,�0�q��h�H�BI1�d�@~!�S����5�t�Q���3^ D�uDBg�>'��Ɛ�
����ڑ)��ր��3����
���T�wA/F?�D�(�<�+eD�y�:���h�0�-�^����)(�e������A���`��s����z��`#��:!�`�1��!��hB��(�@փ/�ǀU�݇q	�@7���T���s�X�L���"VT��@�($3d��u�U�d�
���Y㦠A��M �Z'�w	��}�"H`�(����Q��	8Oغ�uP�~�=t�7��Q	�D~3�I��#�<�fi��C@d"!�$�s���(a�2��)V rt����d��`�P��q �(p�'�%DD`�<f�d�L�u<��>&�;Ȩs"��bo�Jz%�H�+B[Q�G�( �
䏖�'J�Q�?���Dpc	פ����A�(�SP'RЦA{]"� �
��$�RA9>Cv?�a���!=ty��g3y	{�b�)�2��X?@��|�:�	����	��.&.#��)cm�$��o���8١ܿ�LE��"�Z(�+bF��}�l,�
���y���D�I��@�	PK����3�U�9Oa�I$w5�bA߄����R��-G��d���E'}\��K�B;�d�3�C�V�_�{�oT����^	��>jX�*��y�b��'���Oa$��@_(~ s��s�]���E����-l?�|�CP0�*jz:��W#�x�d�B(;��O�0�%���J�]A]�<�UwQ5�!A"��n�O�Ak��`\S(?@&�*��d���]3u��K$C���!�/D�>��@>$n��_��"%B �Bt/�l�A<��F\��X$<���k���AW�1�"!:���?��"�֔��X�AE�ͬ�C]�|�����&��Uj��q|��Uh� ���|��ɯ-��
�
\�;�bfa~��Ўi��RR	/�c�~Z�	qL���>GX�*� eԡ��aDX�O�x6�%� B���@X?�G�Y�HP�t&�OEZ#`���	���q(���
�OHU�LD�8Vb�0�{4إ���K$����q�8���W�[Q�䫔�/���-�OD�t�1y	���ǓIQ|qd{�����+ѷ���I>FQ4��_4�o�}{<�a�������B��_F1�b�HrLL���I�F�`84�Ë�#"���}�>l��9H�&�\Q��RG��U/U� �U�i��!�׻�~r	3B�ޕ��F�O�a8�D&�:fH�lSpn�� vLD\��ux�D�+�Cn��|��o�y�qX��� n��MF=�)�t�����B��D�W���R�/�p2:�oI�J�S�)�@'ļD�rC%Y,��W�[�טM�����kM���ܯM~T���>#�+��p��?P^�\��e���M��l��3�L,�IT���>W�!s܁��	�/�Ÿ����@��5�ߔ�%�1`*e@��c
�g�b*�N"�Ƣq���<��\1
l_�|�FY:�c`�<�ȇ��6f�AØ�h�k�0�2\ñ���L�}�|+<�Gz$��*���+QF��6ġ4�\��)��@�`f� VDEB��A�TVm��3��� V¿5�R���cLYWIwG|�� ݯY�s�)^���S�	�J��  ��F[�'�t0O '�k����gW$k<J$=����t�\9��~�q�gq��B����d�*��qO�8����-�%(���/��Y�N���L1	e���+`������aM�8N��_������td��*�t(�����'��α�2�O5�g'�Tl��4�`_RIW$]�9�� ���
�}.���]&c趒D:	�0��S�[B�BA��af�*2�
>��Y5uIB[�gUɔ��VT��"�A�M���,��$��X�:���QG�O����G��S	/��`��U�S�Hz�Lc�:�����
��&�֭�qh���;�(sȿd�}�:#����v��x�kQ1��>�Rez��q�����=u]�����QGUk��{2�C<�d�A���"�0��W���x�s0ߞB���~���[�(�?�0�Fܻ��F��0D�
���]}3b:��1�"��k�{��YM���N�:��%ӧ��-0?4��P0V	���~à����=J��$�Oe�$�ot�'ɤ#���سT�b�"��<Mپ�3��D�r��dSB�MF��I�{ʘ����J{<�Вl�pP���7�t��Jd�c�B�+�%T��q\��ٖ��Ɯ�9���y^a� g���Id{�^��q�:R��F�?��U4��v3�2)KO$���A�M�Q	������P@��1�U�џ���
���w���q���XQ�浨a�ɇ�;�'�H��&���}S�X�`��b/�NyJ�C�ǯ˘��P��t�C�\
�1Hd�BLIE,�Ĕ���k�]:er
����0��L6�_ ������8�ɏ	>�'\o�I0s�0V'L.�B)���b��D2Q�<!s�H�g��@:�2�}�f�<	�>k�8K&���[�L�Ǥ������.`~
��$3����@1t��j�9^��1_�-��܇B>M�8���`�ѧ*����1�����ӭX ��.��eʹE`��\6��0V�8�%����r,b�@o0�Q&�#�+e3&~O	}����$�o1�<Ct;
c� �	t!�t\���~4�/��3!��Ҹ�`���W�f�؈"��$ҷ���,�a��8K+6S�\���(쥪5>�K>:�K9����y�љ�l�A�nbj@拄=����t���t�A�`�5�� >�<�	(�E�W��^�ס���+VR@9%��!Qn �ٴ��^�?��>��k�C��<_�<`X�8��|����O����a�D$,2�e�w,a�ݚz��fƾ@�$��xl��d9]���>���o����'Ϯ%�a��H�w��g(�-�9u�ݣؤ
a�d�V*�߂�"���YC`�tkN��{?����|�%3KD��5��rJ�����Ɯ �#t������O����2�#a�%Z�;�]��0<%S>�Fy�2��@lP#��0(�#��)��r���@����>���a���^5�ܿ�����e�N�3"�(%��&{�y�ǀ�9�~dK�ޏ� �;@>LъeA;]�دN>XI"f�I+�m�E����{���O�G�p{G�/E�7���AU�L�>Hg�ɎTP��i���=*�G$��86���[��C(o�D�F\�Q�f�ǰ�io�	ۤZsS��)�#�)���A?�<`�g����(�@~�� =�;��R1�������9��!'�||�t��`+�)��+�6@k�� f�����`OVB"b��83��y���͊�F����2�0]��V��2���&��s�2�(�GR�ި��օNq��ŭM� s%�ݙϑq΋4n��C���	�-QޙJ��
�?I@l�-	_��|z����i/���c.@����m����e�J9
��;���e�i��<��r��ӂiB��k��&[�Xt��n�U�~%;x(o�^���,U$_��y>!��i��	z������@~�C2��КC]qQ�cBߧN������Z.�	g v���\�1g����� ��q��S���w�b�5��	�������.�	 ���8��z�o<���^1�ϔS���;��F��Hl8
�0K�D�w� ����w��?b�!�'�����)��1lx�CB�E��1�:%�r��?婃�f������s�a��h�����!�r�d$�zd_�u�c���F�E������d��l*Ɲ �z�oQ�ɧ��XB.�n�� ߙ���g���mq��=�� �9��&R
�&�?u����qO����}Ŋ��<2擣�L%�~B��4�ne���oI"�u¦Kf>�L�O�Ѡ���sW$b�H?�\)�_�ָ.C�L�\�O��5�Ǻj�!�ں��u�c�G[s��'y�"šT������@y�����<�C >�7��'�T�m ��������~+�E��n�y�4�~�S,�0˸�آ]��x-b�(�\�� ���"�Ũ&��s��	�;��+"%[���H���i�\�I���1��9Yȿ�x��ML��M�r�U�b��@�j�s��5�X?�\��B�<���_�y���g����@9��u~P�[���D"ܘ&�#�/�*1Z�:�+p�Y�#�r�P����Q�|<؛�oI&c��{Q��ř�x�dK��o���6���:a.w�
���o�y�uA.��qh?�ަcn�H~[�U�_�c�$.��?x�۠�N��u�-3#ķ4�݊�U�yԄ��3� ��#fE��T�w	�
~_�x#/
�:��H�����R;���r�r��t6�E���5b����\ʧ���1ޣȴ�����\�Ã�R}�� �Z��Ki\_PPOQg�C	����C��`漋V�lP��D�T"����PN�F< <g��`��ʓW)NNyJ�D1`����K�Q�)�g��vV��d�KU��MݚOH��W��XT�C�9�$�QA����6BS)g��o�=�c��jbv�ߦ�?���%�l����+ �����Y&�s	��"��[khǀSW�%P��l�T��R�I!�Ϊ��m�0�.4�3�x�$���С$Ś �>&�o��!SL��K@�ѴM�f��m�l[�b؈�Ŝ\�᫢�>3U%����xV�0�<~k��M.�S��@��)�'˄�C<��$�(�9�f>�ʙ)�U@/��@<��D�	f�(���\���>��Lp��3�r�.A6y��� ��y�h�r�����?\_']
�7�	4�m����Q=�}��}�V�5�Tu����dZ/��  �|�d�����1g��32�y0��؝{�y�3���oF16}��F��b����>f0��0������/����2�t��bP��>ȵQd��!���+�o
1��/��s�|�'_�@��i�ق��L�|I[��[�Ҿyɔ��sɗ�cՀ�I�ט��>8��<A�l$���d+G�H|T����ϰ��)�:�3�P�˘'�qt��}�ċByx���E�!I�W![@�j�(J�$��(����.�-;/�n������G����C��*�g!٢˔c��v����	�
d�K�u�����o��'��6�� w5b"S@|��~IQ!���X;��I��H�[��&�	�� ���mEb0������L��"�E���=] ,�C�S�C �V���4+�Y!���U��s/�1��t�I��-��þ(�n!ig�|^нy����F�d��D�dX�N���)��s#1?�r�%z.�W��ߠ<�_�!t���T�x���}��.`lـU�f��/h���9'Rl�rVd�@)(�Ϲ|t+[�H�C��%�W���e��,?(rPX1$2�E���;)����ø�8�a> ��c�%��)�q`��=�*�+#����T%w����K�xG����G<I�P͜D���A���"�K	�E�x�-&�W!^D�oH
�M���^'*�~)�<w��S�,r	���D��L���+�����`��(�p/�u#PN�"R�(��J�C�]]2ck��"s�H�X�@{(��a��?f���k:�<���Q��,#?�EnWY7��`�R\汪�.�{�_k����_[��� ��9��	����v�y��E�M_�N>O�|u���I��J�h�]���#QΡH�9�0���$7(��~��M@_qh�ǃl�U�OW5�&�_����͋�ő�/	�'�SL����1��i�7H�'-�V\���G1}2�Ǡ|6��0�x,IEL�Dd΃+��U�ȿ#W%p��)��Ș���%�M�������7)S\�K�2s�Q���͹��4Oy.1����*�	"��(�|��Fq��� w�RJ*��h�&�cN�����+�:	�!~�Q�������d�g��Y�%�Q�t�02�C#a7d����{C��@�ݒ�� �r� gEʋ�9���� ���$����׏$W\�L�����跔9��g�W1�ʚ/j�����:q�c���}a�19(WH'�X�=���H\9���D⩡��@~��\*bIE�V1��u��X���B�u)`�C̅��"���&E��h褐NO �n�K��9(R�D�|i
q��D���f�z	����L�'��[�D��)t��U$�Q�J���U�8��/!	�	$�>X�kq�#(����)&$�&�$sؠn����D��L�c�} �JL|�H�2I��� �]�\�[���$��|�`/Y����cV�C����<�x��r_�@xL�����G�LV��H�CO����y�5�V$��l[��e�@�!�#뗼�gP��P��>]���#������8>YB�Hi�蔗#R�H��o�(Ze��R;�0!}��?c�S#9IM��:�7���r�q�C9+S��N�QٚK��<�_Ag���b"*�u��V,B�A�+�l}?�@݁�Rĥ _�DXeĒ���ȍ�������-����H�$�R%�	�;"�i�]��'�E�Y3�l��5���Q^a0��G�=⤥� ������z�U4�y�+���*ϻ'<�]X}J"U���cֈ�B �9��1����oV��=T�V�oE�ÒB���7G�KX?���F��_P�=�(�g2┑K]�Z���5��.K�R��w*��Ц��T%9�&��YU5k �[7񉀭)�, �	�MQ��_��)���Q�[qN�0�ņ$+��)�C�H�`� k5�Ori5����4��#���:Ƃ�ʝ�ϖ��I�JC�oV�#��J9L��)Q%�0#�����N9�@��*����4:�3�@�r�Ɉ�]�F�ǰ�r�i�g��:�@8}���x@+/�@��"��e��-�'������F3��2��`��#ʿ%�IED��i��
ь�@���1\��!�a܃��@�8?����?Y��������ȧ!�T�������%�R ��A&�?��`]����{Q,���r��F~d�Z�8�4�z���C�~ ��W��y�<�x��}ǘ)�HK��9/��%`�(!R\��XנHl�uByT�� R>�H��͋2��!~��,r���'���[d6�OQ���>k�?<?�㔈��K��򒊔c"Q��b��L:�f�Y ���8�U���$�$���\��~~)V%Sm����&
�A�p�&7�H�F�z�D��N�iʃQ	ϯ����!Re1M4k����e=a�E�K��%�q��l]3k�<�A�(�Aqʿ�ɗ�x{����n�fO%3�!�WE��V^g�WD�����	ƒ��A7S9⇦n�ywȕC�E�.k�uGy�r�B:�4������U��E|�*ċD1m	�[b��p	"�o���Q~���^��'�$���������V̔n;�5��2�:����Ǳ��v�$2��ym���ޢZk/�ߍ�J*�ܡZ^Tk �-��8A�8�d����}�� �w�U4s �}�����F�O�{A~x��#!̇�}sL|�D��uI'�|�<�Hh���㜜�Q <ay5?A�%_�w�xs��׭L���B�S�O&�Ꝕ{+P���~�3�b:̦B|�"��!�R:՟��@ڳ@�V����ND�+�>�D�f���Vɖ�����M���b����F	��QI�W9O�γ	�b����� �^,c�s�P?D��jz�&?�@�h��yMg�xZ��Pʓ��]���dլ L�CA����wC��+��"�@�X��Ʉ�B^1�կM��2�:A>�����ȹ�e�s�V�t�d��=�=��|ĝC5y��6��ˡJ�2���oLy&� �Ө��fM'n�c�l�/e�����.R�&��3]V5k�8U'�(/N�5O��LP�V'\,q�q��R�,�+�6��`�:�n�ꏥ��R.�Hy���:f�/��B|S�7��Yk���-�/�PU#{�&���2´=4���7h��Z�1#���������}�/D>r�A��?:��~)I���̏B̧H9�T�J	� ��x]��й-�X�����K�P�;aPa���XI������xe�C~:�*�j�ɩ��¬h�q6�b�M��"�/�+,�� ~
A&̍Hu�@�V�Z��B�UU"�S�ݔ�ә�R$����hI'>V�Ǻ)�q"�2���=+�@5&!�H\�|�ꚕ�@���A��ʱ+q�Ώ%�Z�+�m����|S__�X@3kw��Utӟ
yqIPb8*��4���ym��	��a��?�?���T����Ts�
��񥪞��(���� �.'R��#R�Ke쟜ǈr�%����i���PBǜ&�;�^`kLn�_��D���W�E�WE��AQ�|B��;�|�"Ƣ _C|eX����\O�m��Ũ���P�D|��obΖ�qp����cV)'y�����Z��cI��t9�T���$�0;�	�?#fȪ'K�Yks��*��¹J��E���*q�Q�1�h�`���/��<���n`��MȳN��:�K
�W��"D��/����U�}�Oщ�}12��&ߖF���	9�T���:�tɜW�lv�/��&�Hx	I49�A�i����
V`'�҅Tԟ��T�I'!Z;��\�<�L����>�F�7�	�g/�p�|��U������E���+�y�E�ݓ?�̍4�4������a��F|8<���է�P�ɬ#�Xe=ՠ��ZAnr.EM��C����J滛5���P�,����Y��R���E��$�\���'~{��P�7�kS.�Y�F'<�@�*q^�G�Z���e+6�8�/�Z�Ċb�����(S�]4q�2q����w�x<�8Ke�1	����f�&X����0qF���NXy�qs^I��#��C���݀����h&�_@�:ӧ~E�q%.'Z�\>I<�SA.��b�q��Ʉ��	���4�?E�Ck��f<�x�M��L��^�����"�"��?�h�g���9�k�v�q~ri�e�r��xW�/ ']C�P��q�ת�`�������,�V�����XG�&$��E���qҔ�B\g��.༢9�u�#�P}t�X��˼ƞ�nC���j��<�H$�E��ñ�*ּ����Xi��E�s�:����T���h��ᾋ}�y_	ר�;i<ND�W��Y�|�B���@N �0�:}<vj�A*��g��&)V���8*�"�B@�L��E��o�8�e�"������:�13y�5����ΨG�B�� �r+87�H�}�>�ʄ'�
�_(��$�~�<k������\[�#l�_�*��UG���b�a�0�| �^ �!���)��9�j�
�\�!�2�� #����=*��P�>X����U�F-ŧ���1�$'���InH&���уv��f�39N�sD��<�<B0����9G��ø��%p;��ȱ��Q�#�@"�ܥ=[%l�@u�x�B"^!́D���$snb�� QmS�D�e��|>⻁��%�!p̋�\��"�LU�[�xy$��Ԭ<���k���7���\��Ss�3WC��.c%]F����	�S.0�a��6�����z�D�	:��T�Q�Ln"�1KW�MU�?��MqV�}�����)[sWL<���������i����)��/�c��z��
a�5��RN��F�����Yw�����V�=�t�)^n����Bγ� �E��U�SKG�!g��4�Y$�����0>F92�Y�}��~��x�dnGQ=4ګ�wZ�<ѬA�r���̚dVNH����&��!�8'?������<"�<X�<N����|3h��3 W����/<$�c&�P#���|"�����w ߋJ� h��pv*���_+�h�v�y^uC�w;C��D5����H9�f��.� w����)4Η�#�Y���Juʨ ��V.g��+d� ������$\�BrJ$�P��Jd7�<'�Cy-,�8�u�"̼Lu� w�j����E��B����s����H�����>q{�^h�����jg�KG�֡�X�l�X"��ZN��]� �F%�qʣ�Q�\ ړx�&U%�>���rZ	�I>S�c�2浘�V<�I�퀵ǉ����q�#�s�i����[�O��u�O�5ɨ����.���<F1rx�4�T�YG���`K���<<�s�I��+.p> �p���s�%�j�b]{��hޫ{�{�$S�u��u~��%R<D!~���4��J�[��	��>������>I#��T?tG�U�������M��R�	��Z%\&	���J8o��:�@����;�P$�c����O��&9Έӄxi1n�x��l��!R\�������z��7C{5�[���qd�)��ī���x�ώb��F�\_լu�;�IP��s�"�Ķq��Ǣ� ��x���(�J .O��#�2���'���+��	62Ճ�y����:v�3%���sz�Ns2�?��qkh�!^AL�%~G��$ט�s���%���u<@'u�&�9�,�9$X�D6s>w-Yqب�)&ϷD5�q���OU2�۱��ny=+���&���y���UyK��"�|T�A?N���F�b�+���6�X��|l�j�>��{�9�
��O`��Dux�7�>���ԉQ6�k^_9(�Q�O�*��	�QC�QD�֘L�,��(΀�9���D��b��A|S%�( ?�<���jĻ��)O96־D\d�N��s"�:�8t+??����%�@|C�L~Tk�7֝������}�'!�9va%��C|<�H1r�|�u��`+o'�e�j�
����u��A������$g;�mVtS���p��D1L�AC�|���j����@9Iė:�h�w~㔀%�7�j��i=&19�Y�bE�_�B�M&��Fz�l�Q`Ω�<�_t��Ę�e�7�u!0�
uP�_�}�"�; ?F�B)]�3�K����Lur��:�`�gC_�4��L�?�sq{��ׇ����B�+ʵ�/�[�ډ��Q��tyI��iT�r�%�r�\f�|8��L<�R:�?��E��� fZ$�b�̭�|9�Z9UD�s�i��0o�b0���\8��OIרv��:��]�J'ܸ�RM&�g���K!�&�A�ڝX��t�o�(��u)U6y�=2��h�R]/�/(���~�#֏ci1Ɓ�0R:>U��QM:��}λ/#��)�n!s��p���J2kɂ������\��ר4q竔�I� ��$�4zW)w�J9B��1q���1��H��7���2��r��2��:�7!�s���Ǭ��������D�̈́�#�|�`w�����!�ǜ��4�y�/��n
�ǒf��&� ٕğE���H�y	q� CT�q��25����qt�V���s�u̙Z�Z_j�z�T�ۉ��Oxm_Ν�Y�-ˈk5�tȗEIĳ���8 ��2N"��D��c%rN(�4��7E�E�&aP �ª�`����D�bS�iK�s~o��nh�j.ITcM'�Tʑ!��&�~I�E�0���^��-���
�0%����X��`��bL�?�֚�_R����5�k`����%��H� �N��*����V�r��W�E%Lq[a�I�B{q��5gDP̺h�^*PlA�}���t���e��.��*բ�(����B|ȺB>!���b�;�S�0w�Β�c@B��(���\��p�*��|@�x��o�x9.�bl�5>��q��C��&5�gU%M�|~��#���6����?�ɿ�yqTc0�ɣ(Q]K�/Eck}J���9EcӾ�>�3G�xnǠ�P�\�
�����+�q��<�~��C��
be^;��=�\*�� �T������a�<�q�Y�:�E���� C�:��D{$bj f�r�Ե�M�յ��@����W�u{���c{$ĕ .�j-���,���	�%�z��b���N�F5�i���
D���9�h��V>z��1&"��D���]R)�AO����D'Nn�<ȼ��@�U\/$�$��)�2� ��:��*�q#v�cA���h�y���PN6��$k�u�x�O����@���r��ːd��v�D��2ᏸlL�7�e���0���Nr2�du��EQΘ���{(�Z���@��T!�F^+[�rS�|8��DuN$��is���$w,������H����!��,S�6���d�#�T���1>(�%���S=^�`�s��@��4��g�ɮ(�[�<���#3f�z��r�pD��Ԭ�5xTE��M9��L��l͉����)�ީ�>,�J�(7]6k֋<�I��B{�ʱ�X�k��f�I�9xT��ĝ��E�4�E�c��<�M�����^�C?&�	TĢ�OUɗ'NU6뮀Ex��k��
�
T�E&>T����6�v��o�2�'S�,`x���V���}	� CD�j`�< ��.$��J2�L��D�@�D�]A{��1(���8�T+�D������c��=����A�Y�]4W�:�\�R��^���5�Yt3V���?Ey��U��	tpQ1�2�����̸:b.�u;)�c������#�����u��)�&?�&S>��"�x@W�̚�2��cz̗��&������zǠ��f��u�|q℧����G{'�Ӑs_2y��&�L�҉u�}T	�.S,��ky�8���Lyۣ!_��hr�?_4s4A�����`�E��@�����Nu�+M�	:qk�D��|����s�h֚�:�ؚ�"%��Q�$��F8FΟ��7+W���;��>"K��W�����8Ic��t¸��B�t�B�O�%��룈�ZXqPR?`�$�[i�׀���Mx���QL�8�#���1�k֑-Jh���If�	��.+;��,�b��|!"p�
��-R�O�y.�Ʊ�wѱv�D��&w�L\,*�ۗM�L�弶7�v�}@6�t�;�1��O��H�n%�B�FTk`\���U�w��,[��t��J��%��2ka�|
��A.d�o$��l��%_����9/��~g��$�$�(��`�+�P�s@�b�i�q,,r�����"���/2�M�$�ⳡ�-�G��H:�5�r#1�0q�*�%���#siToY���P� ����צ�nv5�u\+��H8q��!��֓�ǟ��`�K��,j�EP��
��d�ʅ��"T���F��1rZz�3�md��ű�d�5G?�)_�u�3��)�G�O��2���&ݖ�������[qL��R��{��[�1�L.3�u~�����x}I'<�c�7�Mk�[���:�wt�-���]$�b�%��|�	O��_��O6��}*�{)sn�3�n���D�rF'�T��(�a�7���`�vr(@\/=�C�y�؊NX@ڳ1ה�=�n֫���w�������ތ��7J�09\�c��R�zl�oN�*���OB|�"��6kƠB"�;�W������U�	�^����U��2��L�{g�뜓N����w��'�jS�f���\�	?e�A�U�k�R�x��H��:�FE�w���T���=1�y�4�)�2���+�K2��#��S��c��3���d���4�WЮF�.���%�v	�P4��D���ǃ�~)I��q~I&_���*a})���Nu�EΩ
y�A~;�j��f��LX�0(��q ��qM�!�tE+�+��#����C�.�ǁL��W xTM�m�S ��"�����/Q�-����5��:�G>�'V���kzS�H�y�x޸�cD2a5?ﮉ���)&�P�t�n�+�$S��8�@x6��`�`)�[U0y��;@!��#�1�n��w,�����xX%�DP�:iȑ�N�	�+y�Rʹ���ho%� ��"qhJ����C��ה� {��k����Q=0M�փщs���xn)�/e#��T���O���'њ��T�X�yt�O�k��VH&�f�-�*�]�%,�|�����So�|<���d�-�����"`y��*�TRBn�_|�X��|��@P�6^/N��W�tL��;
:�@��%>d�j��u���T�攒��'_�����k�)�}G�_3q�f�<��J� 9� (7I"�g�g�+�ʡ*�|�$�j�#��}��g^�r�H�ő���1\�<��Vx�/+o��1L�ed�I������BBߙj��#
�����)�{���1�D�J���t'��sU�ݓ�C�ף\`�k���IL�!|�t׺��m�n���`<�#�����{"�L0�E(�����Ǭ�)��H�K�xj���IX+�bp<����F���Fe��U+�k��z��g�bD"�H�}I��-馞"q�d�Z�c�WȏXuY N�8�U�s��ۭ6��6�H�Ɗr3����V	��3cr��ayH��~F|Tb�w �N�@��\fR,]�{����&`c���L>t�l�5�D���媕|��:��xa��G>c�{Hd?��WD��5���[���2�2Y'~<�����&7Fzn[ҫ^�8��u'���z`}�Z�Z�Ȗ���t���k�O�Hx�w1'T��P�<��]�u���A�.�M��|z��5k�G�8yU��<%(���R�wA?2�p!�q&q�q1ȼ��6�ʕ��D\崪���v�D�`"q�I��}Jh����<7�r�(������?�̵���9�)�1 �#/�L������>s�_�9���2ST��FkI֬��B>�τtU�C:���	�<?�s�T�ꗧ�o*�="�b�r4DZ?�b�`�g��V�-A'��+	υ�n��e�_f�!i&V�Q2�����A��&3��e��QM=uB���_��KQZh��>��2�(�v�����ȯGX-⍃��[�F
(�E��@D�dQ�f��1̒d�PGL�nbic�	f=x��q�K��!,��+�_jr� �.b�xL��ƹct�^+b��B���8�꟧���K���
����{�"�*� �('V��ٯ�T9�WL�,M����c���E������O�tz�L��7�_�/G�S:�Ê����yM�*���(c9����5җ��W���∸�h�_�M��

5���&�T���/w��+�����)ui�P̢K�o��� �D7�ڨ�R*�/�6��+���J�2lf�2ߨ`Kt���`)�]�ן����*B����o�ukY'���T`�E��G[�#",q!�	��%0�Ϟo<��O-�-�������O�
���b��1p߸��m�ԧ��O_'�~�9"�b���$���tw��iZ˷a݆u���q�n���o�U�E�65�n���E-����3<>��9!�w��^����C�Mq6z,><�o	
����ą�2Ƨ����1jn�݌�5�czǆw	���Z��i��-�R9>�G�w�	���ۥ*��iHL�2�[o�	���FGZB�-�ތ?񉈋f��b�Ol��Ȑ��8KDt����(ۄ�F{##���,�qa|��9�S�� �g+6G<Cc�w�3^/$��o������ȸ*"8o��>����4lЬQ��5}-F�G���3����6M���
h�ۺ����GY�#B�����^�>������ȿ�oSK{7�7��Y�QA	�!���۪����6:�NǆGu��tBT���Ix��gûDF�i��lV`�k�� *Y��#{Y�����+�{�}j�r�ŽLLh����g9�Pe�?<*���q����Q��C�������ƾ�ۨ������N��8�vm>Øb�}a�t�q�aK�1!�����oʊe�+D�����a���c��\��h�4{Zx��k{����X�p��B%Kxevc�lYk#�6ѫ@�څw���+�v�7����<ʊ�\`t��p��_������]Z���F��	��DGc���+�B\�t��B�?�A�g4�hH��`��_�����C�)�^b̦��(~�����c�͎ٛe� $�����mo��c5ć��<$6�����Fu	2�f��c4�dp��Q��������2'�;=��78��R��k�Y;�jH���w/����X_Ʋ(��C�g������8tɿ��Gtx�ъ��x����?_m�+c-�/����o��裠n!Q��Œn��[�a��C=�=�l��������4�9�b����_��?_d<!8"�w��)��D���n�.�����ѱ����s�Od{��$�#y[�B�	��'��(KU��˻�x��HvG{�h,�*c�G���2��3�-MX��҉4�4ѐe���T��e��Nb�\��̓=L��uX�>��;�\ ����k��Ն"��l֗���Y�bN�r���e���8k���ϛ��OƉ�� CQ@]��<{�y��kl���e{c;��!������d����a�Ow.><2��3��-����H��TJC�i�%D�=�������v��u`�ܫ��+�7��+��8�BglF�)p��ř�V3;p�;�uvb�0�+~t����Sp��W:9���El*��C��[z����{ٲ�G%����͌�v��e�e�bI�3��4n�LtT�/�1.��0u6>����������1匫��h���ߕ�0~l��Z�6j\rF��5������ߦ;	�[�
��/��Sڱ�z�$k���ހ�n�ͬ�����{���#�XO~��ڑ5c{�23��������Y�,k�?uY�_{����ʯ�Y��ݱ��,Úؑ�Wt�N�Fm���v�M}�E�v�o���?{����E ת�ClP<��VA� ��h�fS��K���Z�&B뚅�M���a���!�+-�� 0�I����r�*E�Ar�+)����WI�;����EtP��������;4<">$�ן�7q�7��U`Bp8ݎ��'6(�vxH�PC���5>6�P�6li�}#(�#��廧;����ޙ�C5��עAcw��A����>뗳4k�,�xq�Q9�P�"Z���͚7h�m�����o͚�4f�|����`�htN v�?�H����G`D8��@�����9���1���}j4+g��r����_��O�Zu��5��к��)�K����������7.筎�46��b����E�z���1�ٺf�S��Iq�Q8�!�����F'��~�N�Y-1��A!q�]�9���Xe@["�̃�θpc
2����EF�Xh���i�j��F��}5�b�[�
&��۫+B w�KB*�ۭ�R.E��A�\�M�6��맻g4�G��#ڬ�fzzzzz�U
������7B��q�b�^�p˾�f���y�$�x^�m3��+Y��N�7T�@�Ʌ
 �Z|������T�s��*�{�	�ܣ���/$��PUќ��¯I����^���Q���V���Weu�RM�ᄼ�_�?��ש���\3Rx�7���4�9F�g���iu��n���ޒ��O���o޾;;��6%W�w����h�3��=`H����A�ĎuDޱy>�	6��ٝs�l�a���,N[�2�;��ED!v�[3�!f3�֒��vq��pk"��}������4׋�S�����dQ\P�GIV�|S�Y��JV�Дg����IxQ�.��b�h: 1MN�B�"���v����(0�ٌ�& ���3���mg�o�p��\���<Y�A�v^Rj�x�I �y<��^�ⵆM�]�v� u�W�5��/ҕ.��@;Gq�A%eа�%�h��@\]��g�mu;��h�Mex[��L�ڏy��I*iv7��s��Ɉ���B��Xz�V�B���sO��Z���i��w'G�v}��;/-�po�=�2Sw���%��<���#q��C�	lpw���⍶�u����R�Q������I��H���ӷge߯ +ZD4�G�n�밸t�ˎ5�%!�߶������7@X��
����zE��wk �7iH��Y��ix1�\��8V=�oڢ���u_�|Im�j+>���&�̗�,���@~�b�H�e�:���r>�+pMg�[��:�'( ��S̕sIOU�IL�8៭���%%C�:�tB����!�*��|We�������h�^�b|㤈��Zr��i�����.�
_B)w��=�'B����Vvj�ğY��������!@DӨ=�=����Kus>t���Q���,�5��+7@1oi�H>�S�
�1�uZP��mu�)�����W�|8I3>�4�}�A���
=� �:H��`M]��s�q���T@�P��"�V�T�)2P�}+xW1�H6�
��].I�,�\Y��m�j%�؂�dܐ�]k����2I�����}��k�/�E��bGbi��[�0)����3rNg՘�=AJ����94 �Y�g���#yed�V������_��#��]
y��UWrW9������Oi`�g�e'��Lj_Jf�y���.�D{5��G2J�L1��u���+r����i_\Tiv�/��I����t{P��I2R_Ӱ�j�i_$������|\I��s|C1F��G�(�`��T�X7��'yq�)�!�-���F�Ҧ��r���z&��}����qz�>kD�����Ą�ESB�;wP�^=p˂���E`��Wt���"x"sk��,��trnd���n����V��{����{��¬�t!��k�L�-f���KuB��@RQ�r��&�w���mL��P�d���� �S�1�,�?�#�T�J���kK>!]�e�XJ=�J���'��-e^�X��-�Ps2�4��-ys��s�^�J;:�C`�?�9}��sOll,�﬏v(�B0I���l &��\oP���IĨIi��siTY	6�����"�&����r�ܴ�{��-��3��ݨ�qY����_�����-XN�T2G��ĻO��U��|u�
�H�%gn���~L!�L��҆��}��M�r�����M��� ��8�A��ΗI��X�@�H��Q�x��^�Ҁ�/�~�� ��<~��(.�&��Ж��#�;^BM4@�d��z�j�0�����船�r[�76��{�^*,��wo?|�M_1"=xp����=���z�8J�*2�JT�e#������(4�!,;��0�b?��(��7�87��ipU���� ��%�N�]�̛��u��ո�b*�����m�Hy/�J��S:hPc��u��cE6��8H�^t��Mb�Br�Mg��9���1�:ekx�HON�;�\,�<�������px����xd�-V��p�"7Q �NC�J���J�����ms2�t���'C��;gٞ1$m6�qT��Z+�1��E��6����*����c�tBO>�R.� �F�]�/��S-S2`�������.}!s~���q�H�Joޞ������_�NE�k�c�RK��P��).[ā�ߏ��\���%���P.�/�耣XNDr��ئ쉷`s�C���|08(fɍ>�5i<�_ƹ�M*67?����E�+ _�4�X��ůo�W��㢃iqA�1~�F�C����u��B`>�yF[���_�i�j/W��hD�I�M1I�ay�y�����I�F���֏\#>[h�7n��F�$�t��W�r--y��Qh��;���(
�������Ǽ땨�մ��r� Ѿ�I�}�-��2E��w��5�֕PE'��ˤ�Ix�6�Rd(�uϪ�2l��xw�Y6�m�_FV,�6�WܘSdL��_݋z^�����Na��צs�k��j%��jE��;��Ւg��ޒL�������|$�0^>ʐ׆�i5K��~C^���P:���:x�_���g�퐬#w�i2�f��D
�d���\��3�j�/�S,�Q�B%Hx�өF�F�/ݞ��Z��Tj��s�R�7y�V��}��)�}�!'k�uk�QS��h�k�q8S�wX���}k�o)�O�.F��
�=��V�`�>B����d���HYp}��U.����M(�:�y��h��-���'��rv[��̋8�3B��gD�?�4q�L�-��eA9H^�+��>�٥�Ѓ��0�b�%�O��y��Z����	��$�3��x��4�6g���Y��K�"�\�#�HC���yxk�;/YUf�� }m�-��|Ȥ��WU����r��J`b� kMJ�򩕛�^@�������*Y��ӭr�VS��I8F�)�{���5��Slm�FqC�Ms�4��k��g�����s��Į�\kxl�ן�����z������z������z��_@]� � 