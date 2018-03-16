#!/usr/bin/env sh

#Here is a script to deploy cert to unifi cloudkey.

#returns 0 means success, otherwise error.

########  Public functions #####################

#domain keyfile certfile cafile fullchain
unifick_deploy() {
  _cdomain="$1"
  _ckey="$2"
  _ccert="$3"
  _cca="$4"
  _cfullchain="$5"

  _debug _cdomain "$_cdomain"
  _debug _ckey "$_ckey"
  _debug _ccert "$_ccert"
  _debug _cca "$_cca"
  _debug _cfullchain "$_cfullchain"

  if ! _exists keytool; then
    _err "keytool not found"
    return 1
  fi
  
  _certfolder=/etc/ssl/private
  _debug _certfolder "$_certfolder"
  _certtar=$_certfolder/cert.tar
  _debug _certtar "$_certtar"
  _cloudkeycrt=$_certfolder/cloudkey.crt
  _debug _cloudkeycrt "$_cloudkeycrt"
  _cloudkeykey=$_certfolder/cloudkey.key
  _debug _cloudkeykey "$_cloudkeykey"
  _unifi_keystore=$_certfolder/unifi.keystore.jks
  _debug _unfi_keystore "$_unifi_keystore"
  
  
  if [ -w "$_certtar" ]; then
    _debug "File $_certtar writeable" 
  elif [ -w "$_cloudkeycrt" ]; then
    _debug "File $_cloudkeycrt writeable"
  elif [ -w "$_cloudkeykey" ]; then
    _debug "File $_cloudkeykey writeable"
  elif [ -w "$_unifi_keystore" ]; then
    _debug "File $_unifi_keystore writeable"
  else
    _err "either cloud.cert cloudkey.crt cloudkey.key unifi.keystore.jks not found or writeable in /etc/ssl/private folder"
    return 1
   fi
  
  _info "Generate import pkcs12"
  _unifi_keypass="aircontrolenterprise"
  _import_pkcs12="$(_mktemp)"
  _toPkcs "$_import_pkcs12" "$_ckey" "$_ccert" "$_cca" "$_unifi_keypass" unifi root
  if [ "$?" != "0" ]; then
    _err "Oops, error creating import pkcs12, please report bug to us."
    return 1
  fi

  _info "Modify unifi keystore: $_unifi_keystore"
  if keytool -importkeystore \
    -deststorepass "$_unifi_keypass" -destkeypass "$_unifi_keypass" -destkeystore "$_unifi_keystore" \
    -srckeystore "$_import_pkcs12" -srcstoretype PKCS12 -srcstorepass "$_unifi_keypass" \
    -alias unifi -noprompt; then
    _info "Import keystore success!"
    rm "$_import_pkcs12"
  else
    _err "Import unifi keystore error, please report bug to us."
    rm "$_import_pkcs12"
    return 1
  fi
  _info "copying over $_ckey to $_cloudkeykey file"
  cat "$_ckey" >"$_cloudkeykey"
  
  _info "copying over $_fullchain to $_cloudkeycrt file"
  cat "$_cfullchain" >"$_cloudkeycrt"
  
  _info "creating cert.tar to be reboot resistant on CloudKey"
  tar -cf "$_certtar" -C "$_certfolder" "cloudkey.key cloudkey.crt unifi.keystore.jks"
  
  _info "update permissions"
  chown root:ssl-cert "$_certtar" "$_cloudkeyey" "$_cloudkeycrt" "$_unifi_keystore"
  chmod 640 "$_certtar" "$_cloudkeyey" "$_cloudkeycrt" "$_unifi_keystore"
   
  #_reload="service unifi restart && service nginx restart"
  _info "Run reload: $_reload"
  if eval "$_reload"; then
    _info "Reload success!"
    return 0
  else
    _err "Reload error"
    return 1
  fi
  return 0

}
