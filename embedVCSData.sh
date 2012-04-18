#!/usr/bin/env bash
# vim: fileencoding=UTF-8

shopt -s expand_aliases

alias save_IFS='[ "${IFS:-unset}" != "unset" ] && old_IFS="${IFS}"'
alias restore_IFS='if [ "${old_IFS:-unset}" != "unset" ]; then IFS="${old_IFS}"; unset old_IFS; else unset IFS; fi'

declare -a PATHA
function split_patha 	{ save_IFS; IFS=':'; PATHA=($PATH); restore_IFS; }
function join_patha 	{ save_IFS; IFS=':'; PATH="${PATHA[*]}"; restore_IFS; }
function uniq_patha 	{ save_IFS; IFS=$'\n'; PATHA=($(printf "%s\n" "${PATHA[@]}" | awk 'x[$0]++ == 0')); restore_IFS; }
function unshift_patha 	{ PATHA=( "${@}" "${PATHA[@]}" ); }
function push_patha 	{ PATHA=( "${PATHA[@]}" "${@}" ); }
split_patha


unshift_patha "/usr/local/bin"
[[ -d "/sw/bin" ]] && unshift_patha "/sw/bin"
[[ -d "/opt/local/bin" ]] && unshift_patha "/opt/local/bin"

if which brew &>/dev/null; then
	brew_prefix="$(brew --prefix)"
	unshift_patha "${brew_prefix}/bin"
	
	if [[ -x "${brew_prefix}/bin/python" ]]; then
		export PYTHONHOME="${brew_prefix}"
		unshift_patha "${brew_prefix}/share/python"
	fi
	
	unset brew_prefix
fi

pfwp="Frameworks/Python.framework"
if [[ -d "${HOME}/${pfwp}" ]]; then
	unshift_patha "${HOME}/${pfwp}/Versions/Current/bin"
	export PYTHONHOME="${HOME}/${pfwp}/Versions/Current"
fi
unset pfwp

uniq_patha
join_patha


function _has_git_installed 	{ type git >&/dev/null; }
function _inside_git_work_tree 	{ [[ "true" = "$(git rev-parse --is-inside-work-tree 2>/dev/null)" ]]; }
function _is_git 				{ _has_git_installed && _inside_git_work_tree; }
function _current_git_hash 		{ _is_git || return 1; git rev-parse --short=12 HEAD; }

function _current_git_branch {
	_is_git || return 1

	local branch detached

	if branch=$(git symbolic-ref -q HEAD 2>/dev/null); then
		branch=${branch#refs/heads/}
	else
		detached=$(git name-rev --name-only HEAD 2>/dev/null)
		if [[ ${detached} != "undefined" ]]; then
			branch="(detached:${detached})"
		else
			branch="(detached)"
		fi
	fi

	echo "$branch"
}


function _has_hg_installed 		{ type hg >&/dev/null; }
function _inside_hg_work_tree 	{ [[ -n "$(hg root 2>/dev/null)" ]]; }
function _inside_hg_archive 	{ [[ -f "${SRCROOT}/.hg_archival.txt" ]]; }
function _is_hg 				{ _has_hg_installed && _inside_hg_work_tree; }
function _current_hg_branch 	{ _is_hg || return 1; hg parent --template="{branch}\n" | head -n1; }
function _current_hg_revision 	{ _is_hg || return 1; hg parent --template="{rev}\n" | head -n1; }

function _current_hg_hash {
	if _is_hg; then
		hg parent --template="{node|short}\n" | head -n1
	elif _inside_hg_archive; then
		sed -E -n '/^node:/{ s/node: //; s/^([0-9a-f]{12}).*/\1/; p; q; }' < "${SRCROOT}/.hg_archival.txt"
	fi
}


dunno='¯\(°_o)/¯'
HEADERPATH="${BUILT_PRODUCTS_DIR}/include/VCSData.h"
mkdir -p "$(dirname ${HEADERPATH})"
echo -n '' > "${HEADERPATH}"

if _is_git; then
	cat >> "${HEADERPATH}" <<-EndOfText
		#define VCS_GIT
		#define VCS_STRING "git"
		#define GIT_BRANCH $(_current_git_branch)
		#define GIT_BRANCH_STRING "$(_current_git_branch)"
		#define GIT_HASH 0x$(_current_git_hash)
		#define GIT_HASH_STRING "$(_current_git_hash)"
		#define VCS_REVISION GIT_HASH
		#define VCS_REVISION_STRING GIT_HASH_STRING
	EndOfText
elif _is_hg; then
	cat >> "${HEADERPATH}" <<-EndOfText
		#define VCS_HG
		#define VCS_STRING "mercurial"
		#define HG_BRANCH $(_current_hg_branch)
		#define HG_BRANCH_STRING "$(_current_hg_branch)"
		#define HG_HASH 0x$(_current_hg_hash)
		#define HG_HASH_STRING "$(_current_hg_hash)"
		#define HG_REVISION $(_current_hg_revision)
		#define HG_REVISION_STRING "$(_current_hg_revision)"
		#define VCS_REVISION HG_REVISION
		#define VCS_REVISION_STRING HG_REVISION_STRING
	EndOfText
elif _inside_hg_archive; then
	cat >> "${HEADERPATH}" <<-EndOfText
		#define VCS_HG_ARCHIVAL
		#define VCS_STRING "mercurial archive"
		#define HG_HASH 0x$(_current_hg_hash)
		#define HG_HASH_STRING "$(_current_hg_hash)"
		#define VCS_REVISION HG_HASH
		#define VCS_REVISION_STRING HG_HASH_STRING
	EndOfText
else
	cat >> "${HEADERPATH}" <<-EndOfText
		#define VCS_NONE
		#define VCS_STRING "none"
		#define VCS_REVISION 0
		#define VCS_REVISION_STRING "${dunno}"
	EndOfText
fi

cat "${HEADERPATH}"
