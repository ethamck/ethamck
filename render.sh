#!/bin/sh -

JSON="$(curl -sX GET -H 'X-GitHub-Api-Version: 2022-11-28' -H "Authorization: Bearer $METRICS_TOKEN" 'https://api.github.com/user/repos?visibility=public&sort=pushed')"

# Render readme.md
# Automatically run through .github/workflows/render.yml

query() {
	echo "$JSON" | jq -Mcr "$@ | select(. != null)"
}
average() {
	awk '{
		for (i = 1; i <= NF; i++) {
			f[$i]++;
		}
	} END {
		for (k in f) {
			print (int((f[k])/NR * 100))"\t"k
		}
	}'
}

export stargazers="$(query '[.[].stargazers_count] | add')"

export languages="$(query '.[].language' | average | sort -nr | head -n4 | awk '{
	for (i = 2; i <= NF; i += 2)
		print "- "$i"<sup>"$(i-1)"%</sup>"
}')"

set -- $(query '.[].license.spdx_id' | average | awk '
	BEGIN {p = 0; f = 0;}
	{
		i = ARGIND + 2;
		if ($i == "Unlicense" || index($i, "CC0"))
			p += $(i-1);
		if (index($i, "GPL") || index($i, "GFDL") || index($i, "CC-BY-SA"))
			f += $(i-1);
	}
	END {print p, f;}
')
export public=$1
export free=$2

envsubst
