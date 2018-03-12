#!/usr/bin/env sh

#Created by RaidenII, to use DuckDNS's API to add/remove text records
#06/27/201
#modified by helbgd @ 03/13/2018 to support ddnss.de

# Pass credentials before "acme.sh --issue --dns dns_ddnss ..."
# --
# export DDNSS_Token="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
# --
#
# Due to the fact that DuckDNS uses StartSSL as cert provider, --insecure may need to be used with acme.sh

DDNSS_DNS_API="https://ddnss.de/upd.php"

########  Public functions #####################

#Usage: dns_ddnss_add _acme-challenge.domain.ddnss.de "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_ddnss_add() {
  fulldomain=$1
  txtvalue=$2

  DDNSS_Token="${DuckDNS_Token:-$(_readaccountconf_mutable DDNSS_Token)}"
  if [ -z "$DDNSS_Token" ]; then
    _err "You must export variable: DDNSS_Token"
    _err "The token for your DDNSS account is necessary."
    _err "You can look it up in your DDNSS account."
    return 1
  fi

  # Now save the credentials.
  _saveaccountconf_mutable DDNSS_Token "$DDNSS_Token"

  # Unfortunately, DDNSS does not seems to support lookup domain through API
  # So I assume your credentials (which are your domain and token) are correct
  # If something goes wrong, we will get a KO response from DDNSS

  if ! _duckdns_get_domain; then
    return 1
  fi

  # Now add the TXT record to DuckDNS
  _info "Trying to add TXT record"
  if _ddnss_rest GET "host=key=$DDNSS_Token&host=ddnss_domain&txtm=1&txt=$txtvalue"; then
    if [ "$response" = "Updated 1 hostname" ]; then
      _info "TXT record has been successfully added to your DDNSS domain."
      _info "Note that all subdomains under this domain uses the same TXT record."
      return 0
    else
      _err "Errors happened during adding the TXT record, response=$response"
      return 1
    fi
  else
    _err "Errors happened during adding the TXT record."
    return 1
  fi
}

#Usage: fulldomain txtvalue
#Remove the txt record after validation.
dns_ddnss_rm() {
  fulldomain=$1
  txtvalue=$2

  DDNSS_Token="${DDNSS_Token:-$(_readaccountconf_mutable DDNSS_Token)}"
  if [ -z "$DDNSS_Token" ]; then
    _err "You must export variable: DDNSS_Token"
    _err "The token for your DDNSS account is necessary."
    _err "You can look it up in your DDNSS account."
    return 1
  fi

  if ! _ddnss_get_domain; then
    return 1
  fi

  # Now remove the TXT record from DuckDNS
  _info "Trying to remove TXT record"
  if _duckdns_rest GET "host=key=$DDNSS_Token&host=ddnss_domain&txtm=1&txt="""; then
    if [ "$response" = "updated 1 hostname" ]; then
      _info "TXT record has been successfully removed from your DDNSS domain."
      return 0
    else
      _err "Errors happened during removing the TXT record, response=$response"
      return 1
    fi
  else
    _err "Errors happened during removing the TXT record."
    return 1
  fi
}

####################  Private functions below ##################################

#fulldomain=_acme-challenge.domain.duckdns.org
#returns
# _duckdns_domain=domain
_duckdns_get_domain() {

  # We'll extract the domain/username from full domain
  _duckdns_domain="$(printf "%s" "$fulldomain" | _lower_case | _egrep_o '[.][^.][^.]*[.]ddnss.de' | cut -d . -f 2)"

  if [ -z "$_ddnss_domain" ]; then
    _err "Error extracting the domain."
    return 1
  fi

  return 0
}

#Usage: method URI
_ddnss_rest() {
  method=$1
  param="$2"
  _debug param "$param"
  url="$DDNSS_DNS_API?$param"
  _debug url "$url"

  # DDNSS uses GET to update domain info
  if [ "$method" = "GET" ]; then
    response="$(_get "$url")"
  else
    _err "Unsupported method"
    return 1
  fi

  _debug2 response "$response"
  return 0
}
