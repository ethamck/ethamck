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

stargazers="$(query '[.[].stargazers_count] | add')"
languages="$(query '.[].language' | average | sort -nr | head -n4 | awk '{
	for (i = 2; i <= NF; i += 2)
		print "- "$i"<sup>"$(i-1)"%</sup>"
}')"
licenses="$(query '.[].license.spdx_id' | average | awk '
	BEGIN {p = 0; f = 0;}
	{
		i = ARGIND + 2;
		if ($i == "Unlicense" || index($i, "CC0"))
			p += $(i-1);
		if (index($i, "GPL") || index($i, "GFDL") || index($i, "CC-BY-SA"))
			f += $(i-1);
	}
	END {print p"%\t"f"%";}
')"

awk -v stars="$stargazers" -v langs="$languages" -v l="$licenses" '
	BEGIN {split(l, license, "\t")}
	{
		gsub(/{{s}}/, stars)
		gsub(/{{l}}/, langs)
		gsub(/{{lp}}/, license[1])
		gsub(/{{lf}}/, license[2])
	}1
'
