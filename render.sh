#!/bin/sh -

# Render readme.md
# Automatically run through .github/workflows/render.yml

license_frequency="$(gh api -X GET --paginate '/user/repos?visibility=public&sort=pushed' --jq '.[].license.spdx_id | select(. != null)' | uniq -c | sort -nr | awk '{
	t = 0;
	p = 0;
	f = 0;

	for (i = 2; i <= NF; i += 2) {
		t += $(i-1);
		if ($i == "Unlicense" || $i ~ "^CC0")
			p += $(i-1);
		if ($i ~ "^[AL]?GPL")
			f += $(i-1);
	}

	print (p/t * 100)"%\t"(f/t * 100)"%";
}')"
license_percentage() {
	echo "$license_frequency" | cut -f$@
}

sed -e "s/{{p}}/$(license_percentage 1)/" -e "s/{{f}}/$(license_percentage 2)/"
