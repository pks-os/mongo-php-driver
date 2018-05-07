PHP_ARG_WITH([mongodb-sasl],
             [whether to enable SASL for Kerberos authentication],
             [AS_HELP_STRING([--with-mongodb-sasl=@<:@auto/no/cyrus/gssapi@:>@],
                             [MongoDB: Enable SASL for Kerberos authentication [default=auto]])],
             [auto],
             [no])

AS_IF([test "$os_darwin" = "yes" -a \( "$PHP_MONGODB_SASL" = "gssapi" -o "$PHP_MONGODB_SASL" = "auto" \)],[
  dnl PHP_FRAMEWORKS is only used for SAPI builds, so use MONGODB_SHARED_LIBADD for shared builds
  if test "$ext_shared" = "yes"; then
    MONGODB_SHARED_LIBADD="-framework GSS $MONGODB_SHARED_LIBADD"
  else
    PHP_ADD_FRAMEWORK([GSS])
  fi
  PHP_MONGODB_SASL="gssapi"
])

AS_IF([test "$PHP_MONGODB_SASL" = "cyrus" -o "$PHP_MONGODB_SASL" = "auto"],[
  found_cyrus="no"

  PKG_CHECK_MODULES([PHP_MONGODB_SASL],[libsasl2],[
    PHP_EVAL_INCLINE([$PHP_MONGODB_SASL_CFLAGS])
    PHP_EVAL_LIBLINE([$PHP_MONGODB_SASL_LIBS],[MONGODB_SHARED_LIBADD])
    PHP_MONGODB_SASL="cyrus"
    found_cyrus="yes"
  ],[
    PHP_CHECK_LIBRARY([sasl2],
                      [sasl_client_init],
                      [have_sasl2_lib="yes"],
                      [have_sasl2_lib="no"])

    AC_CHECK_HEADER([sasl/sasl.h],
                    [have_sasl_headers=yes],
                    [have_sasl_headers=no])

    if test "$have_sasl2_lib" = "yes" -a "$have_sasl_headers" = "yes"; then
      PHP_ADD_LIBRARY([sasl2],,[MONGODB_SHARED_LIBADD])
      PHP_MONGODB_SASL="cyrus"
      found_cyrus="yes"
    fi
  ])

  if test "$PHP_MONGODB_SASL" = "cyrus" -a "$found_cyrus" != "yes"; then
    AC_MSG_ERROR([Cyrus SASL libraries and development headers could not be found])
  fi
])

AS_IF([test "$PHP_MONGODB_SASL" = "gssapi" -o "$PHP_MONGODB_SASL" = "auto"],[
  found_gssapi="no"

  PKG_CHECK_MODULES([PHP_MONGODB_SASL],[krb5-gssapi],[
    PHP_EVAL_INCLINE([$PHP_MONGODB_SASL_CFLAGS])
    PHP_EVAL_LIBLINE([$PHP_MONGODB_SASL_LIBS],[MONGODB_SHARED_LIBADD])
    PHP_MONGODB_SASL="gssapi"
    found_gssapi="yes"
  ])

  if test "$PHP_MONGODB_SASL" = "gssapi" -a "$found_gssapi" != "yes"; then
    AC_MSG_ERROR([GSSAPI libraries and development headers could not be found])
  fi
])

AS_IF([test "$PHP_MONGODB_SASL" = "auto"],[
  PHP_MONGODB_SASL="no"
])

AC_MSG_CHECKING([which SASL library to use])
AC_MSG_RESULT([$PHP_MONGODB_SASL])

dnl Disable Windows SSPI
AC_SUBST(MONGOC_ENABLE_SASL_SSPI, 0)

if test "$PHP_MONGODB_SASL" = "cyrus" -o "$PHP_MONGODB_SASL" = "gssapi"; then
  AC_SUBST(MONGOC_ENABLE_SASL, 1)
  if test "$PHP_MONGODB_SASL" = "cyrus" ; then
    AC_SUBST(MONGOC_ENABLE_SASL_CYRUS, 1)
    AC_SUBST(MONGOC_ENABLE_SASL_GSSAPI, 0)
    if test "x$have_sasl_client_done" = "xyes"; then
      AC_SUBST(MONGOC_HAVE_SASL_CLIENT_DONE, 1)
    else
      AC_SUBST(MONGOC_HAVE_SASL_CLIENT_DONE, 0)
    fi
  elif test "$PHP_MONGODB_SASL" = "gssapi"; then
    AC_SUBST(MONGOC_ENABLE_SASL_CYRUS, 0)
    AC_SUBST(MONGOC_ENABLE_SASL_GSSAPI, 1)
    AC_SUBST(MONGOC_HAVE_SASL_CLIENT_DONE, 0)
  fi
else
  AC_SUBST(MONGOC_ENABLE_SASL, 0)
  AC_SUBST(MONGOC_ENABLE_SASL_CYRUS, 0)
  AC_SUBST(MONGOC_ENABLE_SASL_GSSAPI, 0)
  AC_SUBST(MONGOC_HAVE_SASL_CLIENT_DONE, 0)
fi
