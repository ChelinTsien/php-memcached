dnl
dnl $ Id: $
dnl vim:se ts=2 sw=2 et:

PHP_ARG_ENABLE(memcached, whether to enable memcached support,
[  --enable-memcached               Enable memcached support])

PHP_ARG_WITH(libmemcached-dir,  for libmemcached,
[  --with-libmemcached-dir[=DIR]   Set the path to libmemcached install prefix.], yes)

PHP_ARG_ENABLE(memcached-session, whether to enable memcached session handler support,
[  --disable-memcached-session      Disable memcached session handler support], yes, no)

PHP_ARG_ENABLE(memcached-igbinary, whether to enable memcached igbinary serializer support,
[  --enable-memcached-igbinary      Enable memcached igbinary serializer support], no, no)

PHP_ARG_ENABLE(memcached-json, whether to enable memcached json serializer support,
[  --enable-memcached-json          Enable memcached json serializer support], no, no)


PHP_ARG_ENABLE(memcached-msgpack, whether to enable memcached msgpack serializer support,
[  --enable-memcached-msgpack          Enable memcached msgpack serializer support], no, no)



PHP_ARG_ENABLE(memcached-sasl, whether to disable memcached sasl support,
[  --disable-memcached-sasl          Disable memcached sasl support], yes, no)

if test -z "$PHP_ZLIB_DIR"; then
PHP_ARG_WITH(zlib-dir, for ZLIB,
[  --with-zlib-dir[=DIR]   Set the path to ZLIB install prefix.], no)
fi

if test -z "$PHP_DEBUG"; then
  AC_ARG_ENABLE(debug,
  [  --enable-debug          compile with debugging symbols],[
    PHP_DEBUG=$enableval
  ],[    PHP_DEBUG=no
  ])
fi

if test "$PHP_MEMCACHED" != "no"; then


  dnl # zlib
  if test "$PHP_ZLIB_DIR" != "no" && test "$PHP_ZLIB_DIR" != "yes"; then
    if test -f "$PHP_ZLIB_DIR/include/zlib/zlib.h"; then
      PHP_ZLIB_DIR="$PHP_ZLIB_DIR"
      PHP_ZLIB_INCDIR="$PHP_ZLIB_DIR/include/zlib"
    elif test -f "$PHP_ZLIB_DIR/include/zlib.h"; then
      PHP_ZLIB_DIR="$PHP_ZLIB_DIR"
      PHP_ZLIB_INCDIR="$PHP_ZLIB_DIR/include"
    else
      AC_MSG_ERROR([Can't find ZLIB headers under "$PHP_ZLIB_DIR"])
    fi
  else
    for i in /usr/local /usr; do
      if test -f "$i/include/zlib/zlib.h"; then
        PHP_ZLIB_DIR="$i"
        PHP_ZLIB_INCDIR="$i/include/zlib"
      elif test -f "$i/include/zlib.h"; then
        PHP_ZLIB_DIR="$i"
        PHP_ZLIB_INCDIR="$i/include"
      fi
    done
  fi

  AC_MSG_CHECKING([for zlib location])
  if test "$PHP_ZLIB_DIR" != "no" && test "$PHP_ZLIB_DIR" != "yes"; then
    AC_MSG_RESULT([$PHP_ZLIB_DIR])
    PHP_ADD_LIBRARY_WITH_PATH(z, $PHP_ZLIB_DIR/$PHP_LIBDIR, MEMCACHED_SHARED_LIBADD)
    PHP_ADD_INCLUDE($PHP_ZLIB_INCDIR)
  else
    AC_MSG_ERROR([memcached support requires ZLIB. Use --with-zlib-dir=<DIR> to specify the prefix where ZLIB headers and library are located])
  fi

  if test "$PHP_MEMCACHED_SESSION" != "no"; then
    AC_MSG_CHECKING([for session includes])
    session_inc_path=""

    if test -f "$abs_srcdir/include/php/ext/session/php_session.h"; then
      session_inc_path="$abs_srcdir/include/php"
    elif test -f "$abs_srcdir/ext/session/php_session.h"; then
      session_inc_path="$abs_srcdir"
    elif test -f "$phpincludedir/ext/session/php_session.h"; then
      session_inc_path="$phpincludedir"
    else
      for i in php php4 php5 php6; do
        if test -f "$prefix/include/$i/ext/session/php_session.h"; then
          session_inc_path="$prefix/include/$i"
        fi
      done
    fi

    if test "$session_inc_path" = ""; then
      AC_MSG_ERROR([Cannot find php_session.h])
    else
      AC_MSG_RESULT([$session_inc_path])
    fi
  fi
  
  if test "$PHP_MEMCACHED_JSON" != "no"; then
    AC_MSG_CHECKING([for json includes])
    json_inc_path=""
    
    tmp_version=$PHP_VERSION
    if test -z "$tmp_version"; then
      if test -z "$PHP_CONFIG"; then
        AC_MSG_ERROR([php-config not found])
      fi
      PHP_MEMCACHED_VERSION_ORIG=`$PHP_CONFIG --version`;
    else
      PHP_MEMCACHED_VERSION_ORIG=$tmp_version
    fi

    if test -z $PHP_MEMCACHED_VERSION_ORIG; then
      AC_MSG_ERROR([failed to detect PHP version, please report])
    fi

    PHP_MEMCACHED_VERSION_MASK=`echo ${PHP_MEMCACHED_VERSION_ORIG} | awk 'BEGIN { FS = "."; } { printf "%d", ($1 * 1000 + $2) * 1000 + $3;}'`
    
    if test $PHP_MEMCACHED_VERSION_MASK -ge 5003000; then
      if test -f "$abs_srcdir/include/php/ext/json/php_json.h"; then
        json_inc_path="$abs_srcdir/include/php"
      elif test -f "$abs_srcdir/ext/json/php_json.h"; then
        json_inc_path="$abs_srcdir"
      elif test -f "$phpincludedir/ext/json/php_json.h"; then
        json_inc_path="$phpincludedir"
      else
        for i in php php4 php5 php6; do
          if test -f "$prefix/include/$i/ext/json/php_json.h"; then
            json_inc_path="$prefix/include/$i"
          fi
        done
      fi
      if test "$json_inc_path" = ""; then
        AC_MSG_ERROR([Cannot find php_json.h])
      else
        AC_DEFINE(HAVE_JSON_API,1,[Whether JSON API is available])
        AC_DEFINE(HAVE_JSON_API_5_3,1,[Whether JSON API for PHP 5.3 is available])
        AC_MSG_RESULT([$json_inc_path])
      fi
    elif test $PHP_MEMCACHED_VERSION_MASK -ge 5002009; then
      dnl Check JSON for PHP 5.2.9+
      if test -f "$abs_srcdir/include/php/ext/json/php_json.h"; then
        json_inc_path="$abs_srcdir/include/php"
      elif test -f "$abs_srcdir/ext/json/php_json.h"; then
        json_inc_path="$abs_srcdir"
      elif test -f "$phpincludedir/ext/json/php_json.h"; then
        json_inc_path="$phpincludedir"
      else
        for i in php php4 php5 php6; do
          if test -f "$prefix/include/$i/ext/json/php_json.h"; then
            json_inc_path="$prefix/include/$i"
          fi
        done
      fi
      if test "$json_inc_path" = ""; then
        AC_MSG_ERROR([Cannot find php_json.h])
      else
        AC_DEFINE(HAVE_JSON_API,1,[Whether JSON API is available])
        AC_DEFINE(HAVE_JSON_API_5_2,1,[Whether JSON API for PHP 5.2 is available])
        AC_MSG_RESULT([$json_inc_path])
      fi
    else 
      AC_MSG_RESULT([the PHP version does not support JSON serialization API])
    fi
  fi

  if test "$PHP_MEMCACHED_IGBINARY" != "no"; then
    AC_MSG_CHECKING([for igbinary includes])
    igbinary_inc_path=""

    if test -f "$abs_srcdir/include/php/ext/igbinary/igbinary.h"; then
      igbinary_inc_path="$abs_srcdir/include/php"
    elif test -f "$abs_srcdir/ext/igbinary/igbinary.h"; then
      igbinary_inc_path="$abs_srcdir"
    elif test -f "$phpincludedir/ext/session/igbinary.h"; then
      igbinary_inc_path="$phpincludedir"
    elif test -f "$phpincludedir/ext/igbinary/igbinary.h"; then
      igbinary_inc_path="$phpincludedir"
    else
      for i in php php4 php5 php6; do
        if test -f "$prefix/include/$i/ext/igbinary/igbinary.h"; then
          igbinary_inc_path="$prefix/include/$i"
        fi
      done
    fi

    if test "$igbinary_inc_path" = ""; then
      AC_MSG_ERROR([Cannot find igbinary.h])
    else
      AC_MSG_RESULT([$igbinary_inc_path])
    fi
  fi

  

  if test "$PHP_MEMCACHED_MSGPACK" != "no"; then
    AC_MSG_CHECKING([for msgpack includes])
    msgpack_inc_path=""


    if test -f "$abs_srcdir/include/php/ext/msgpack/php_msgpack.h"; then
      msgpack_inc_path="$abs_srcdir/include/php"
    elif test -f "$abs_srcdir/ext/msgpack/php_msgpack.h"; then
      msgpack_inc_path="$abs_srcdir"
    elif test -f "$phpincludedir/ext/session/php_msgpack.h"; then
      msgpack_inc_path="$phpincludedir"
    elif test -f "$phpincludedir/ext/msgpack/php_msgpack.h"; then
      msgpack_inc_path="$phpincludedir"
    else
      for i in php php4 php5 php6; do
        if test -f "$prefix/include/$i/ext/msgpack/php_msgpack.h"; then
          msgpack_inc_path="$prefix/include/$i"
        fi
      done
    fi


    if test "$msgpack_inc_path" = ""; then
      AC_MSG_ERROR([Cannot find php_msgpack.h])
    else
      AC_MSG_RESULT([$msgpack_inc_path])
    fi
  fi 




  AC_MSG_CHECKING([for memcached session support])
  if test "$PHP_MEMCACHED_SESSION" != "no"; then
    AC_MSG_RESULT([enabled])
    AC_DEFINE(HAVE_MEMCACHED_SESSION,1,[Whether memcache session handler is enabled])
    SESSION_INCLUDES="-I$session_inc_path"
    ifdef([PHP_ADD_EXTENSION_DEP],
    [
      PHP_ADD_EXTENSION_DEP(memcached, session)
    ])
  else
    SESSION_INCLUDES=""
    AC_MSG_RESULT([disabled])
  fi

  AC_MSG_CHECKING([for memcached igbinary support])
  if test "$PHP_MEMCACHED_IGBINARY" != "no"; then
    AC_MSG_RESULT([enabled])
    AC_DEFINE(HAVE_MEMCACHED_IGBINARY,1,[Whether memcache igbinary serializer is enabled])
    IGBINARY_INCLUDES="-I$igbinary_inc_path"
    ifdef([PHP_ADD_EXTENSION_DEP],
    [
      PHP_ADD_EXTENSION_DEP(memcached, igbinary)
    ])
  else
    IGBINARY_INCLUDES=""
    AC_MSG_RESULT([disabled])
  fi


 AC_MSG_CHECKING([for memcached msgpack support])
  if test "$PHP_MEMCACHED_MSGPACK" != "no"; then
    AC_MSG_RESULT([enabled])
    AC_DEFINE(HAVE_MEMCACHED_MSGPACK,1,[Whether memcache msgpack serializer is enabled])
    MSGPACK_INCLUDES="-I$msgpack_inc_path"
    ifdef([PHP_ADD_EXTENSION_DEP],
    [
      PHP_ADD_EXTENSION_DEP(memcached, msgpack)
    ])
  else
    MSGPACK_INCLUDES=""
    AC_MSG_RESULT([disabled])
  fi



  if test "$PHP_MEMCACHED_SASL" != "no"; then
    AC_CHECK_HEADERS([sasl/sasl.h], [memcached_enable_sasl="yes"], [memcached_enable_sasl="no"])
    AC_MSG_CHECKING([whether to enable sasl support])
    AC_MSG_RESULT([$memcached_enable_sasl])
  fi

  AC_MSG_CHECKING([for libmemcached location])
  if test "$PHP_LIBMEMCACHED_DIR" != "no" && test "$PHP_LIBMEMCACHED_DIR" != "yes"; then
    if ! test -r "$PHP_LIBMEMCACHED_DIR/include/libmemcached/memcached.h"; then
      AC_MSG_ERROR([Can't find libmemcached headers under "$PHP_LIBMEMCACHED_DIR"])
    fi
  else
    PHP_LIBMEMCACHED_DIR="no"
    for i in /usr /usr/local; do
      if test -r "$i/include/libmemcached/memcached.h"; then
        PHP_LIBMEMCACHED_DIR=$i
        break
      fi
    done
  fi

  if test "$PHP_LIBMEMCACHED_DIR" = "no"; then
    AC_MSG_ERROR([memcached support requires libmemcached. Use --with-libmemcached-dir=<DIR> to specify the prefix where libmemcached headers and library are located])
  else
    AC_MSG_RESULT([$PHP_LIBMEMCACHED_DIR])

    PHP_LIBMEMCACHED_INCDIR="$PHP_LIBMEMCACHED_DIR/include"
    PHP_ADD_INCLUDE($PHP_LIBMEMCACHED_INCDIR)
    PHP_ADD_LIBRARY_WITH_PATH(memcached, $PHP_LIBMEMCACHED_DIR/$PHP_LIBDIR, MEMCACHED_SHARED_LIBADD)

    ORIG_CFLAGS="$CFLAGS"
    ORIG_LIBS="$LIBS"

    CFLAGS="$CFLAGS -I$PHP_LIBMEMCACHED_INCDIR"

    #
    # Added -lpthread here because AC_TRY_LINK tests on CentOS 6 seem to fail with undefined reference to pthread_once
    #
    LIBS="$LIBS -lpthread -lmemcached -L$PHP_LIBMEMCACHED_DIR/$PHP_LIBDIR"

    AC_CACHE_CHECK([whether memcached_instance_st is defined], ac_cv_have_memcached_instance_st, [
      AC_TRY_COMPILE(
        [ #include <libmemcached/memcached.h> ],
        [ const memcached_instance_st *instance = NULL; ],
        [ ac_cv_have_memcached_instance_st="yes" ],
        [ ac_cv_have_memcached_instance_st="no" ]
      )
    ])

    AC_CACHE_CHECK([whether MEMCACHED_BEHAVIOR_REMOVE_FAILED_SERVERS is defined], ac_cv_have_libmemcached_remove_failed_servers, [
      AC_TRY_COMPILE(
        [ #include <libmemcached/memcached.h> ],
        [ MEMCACHED_BEHAVIOR_REMOVE_FAILED_SERVERS; ],
        [ ac_cv_have_libmemcached_remove_failed_servers="yes" ],
        [ ac_cv_have_libmemcached_remove_failed_servers="no" ]
      )
    ])

    AC_CACHE_CHECK([whether MEMCACHED_SERVER_TEMPORARILY_DISABLED is defined], ac_cv_have_libmemcached_server_temporarily_disabled, [
      AC_TRY_COMPILE(
        [ #include <libmemcached/memcached.h> ],
        [ MEMCACHED_SERVER_TEMPORARILY_DISABLED; ],
        [ ac_cv_have_libmemcached_server_temporarily_disabled="yes" ],
        [ ac_cv_have_libmemcached_server_temporarily_disabled="no" ]
      )
    ])

    AC_CACHE_CHECK([whether memcached function exists], ac_cv_have_libmemcached_memcached, [
      AC_TRY_LINK(
        [ #include <libmemcached/memcached.h> ],
        [ memcached("t", sizeof ("t")); ],
        [ ac_cv_have_libmemcached_memcached="yes" ],
        [ ac_cv_have_libmemcached_memcached="no" ]
      )
    ])

    AC_CACHE_CHECK([whether libmemcached_check_configuration function exists], ac_cv_have_libmemcached_check_configuration, [
      AC_TRY_LINK(
        [ #include <libmemcached/memcached.h> ],
        [ libmemcached_check_configuration("", 1, "", 1); ],
        [ ac_cv_have_libmemcached_check_configuration="yes" ],
        [ ac_cv_have_libmemcached_check_configuration="no" ]
      )
    ])

    AC_CACHE_CHECK([whether memcached_touch function exists], ac_cv_have_libmemcached_touch, [
      AC_TRY_LINK(
        [ #include <libmemcached/memcached.h> ],
        [ memcached_touch (NULL, NULL, 0, 0); ],
        [ ac_cv_have_libmemcached_touch="yes" ],
        [ ac_cv_have_libmemcached_touch="no" ]
      )
    ])

    CFLAGS="$ORIG_CFLAGS"
    LIBS="$ORIG_LIBS"

    if test "$ac_cv_have_memcached_instance_st" = "yes"; then
       AC_DEFINE(HAVE_MEMCACHED_INSTANCE_ST, [1], [Whether memcached_instance_st is defined])
    fi

    if test "$ac_cv_have_libmemcached_remove_failed_servers" = "yes"; then
       AC_DEFINE(HAVE_LIBMEMCACHED_REMOVE_FAILED_SERVERS, [1], [Whether MEMCACHED_BEHAVIOR_REMOVE_FAILED_SERVERS is defined])
    fi

    if test "$ac_cv_have_libmemcached_server_temporarily_disabled" = "yes"; then
       AC_DEFINE(HAVE_LIBMEMCACHED_SERVER_TEMPORARILY_MARKER_DISABLED, [1], [Whether MEMCACHED_SERVER_TEMPORARILY_DISABLED is defined])
    fi

    if test "$ac_cv_have_libmemcached_memcached" = "yes"; then
       AC_DEFINE(HAVE_LIBMEMCACHED_MEMCACHED, [1], [Whether memcached is defined])
    fi

    if test "$ac_cv_have_libmemcached_check_configuration" = "yes"; then
       AC_DEFINE(HAVE_LIBMEMCACHED_CHECK_CONFIGURATION, [1], [Whether libmemcached_check_configuration is defined])
    fi

    if test "$ac_cv_have_libmemcached_touch" = "yes"; then
       AC_DEFINE(HAVE_LIBMEMCACHED_TOUCH, [1], [Whether memcached_touch is defined])
    fi

    PHP_SUBST(MEMCACHED_SHARED_LIBADD)
    
    PHP_MEMCACHED_FILES="php_memcached.c php_libmemcached_compat.c fastlz/fastlz.c g_fmt.c"

    if test "$PHP_MEMCACHED_SESSION" != "no"; then
      PHP_MEMCACHED_FILES="${PHP_MEMCACHED_FILES} php_memcached_session.c"
    fi

    PHP_NEW_EXTENSION(memcached, $PHP_MEMCACHED_FILES, $ext_shared,,$SESSION_INCLUDES $IGBINARY_INCLUDES $MSGPACK_INCLUDES)
    PHP_ADD_BUILD_DIR($ext_builddir/fastlz, 1)
 
    ifdef([PHP_ADD_EXTENSION_DEP],
    [
      PHP_ADD_EXTENSION_DEP(memcached, spl, true)
    ])

  fi

fi


