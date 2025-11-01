#!/bin/sh

ex1_native() {
	echo example 1 using arrow-cat
	jq -c -n \
		'[
		{timestamp:"2025-10-30T23:49:03.012345Z",severity:"INFO",status:200,body:"apt update done"},
		{timestamp:"2025-10-29T23:49:03.012345Z",severity:"WARN",status:500,body:"apt update failure"}
	]' |
		jq -c '.[]' |
		./rs-jsons2arrow-ipc-stream --num-lines 1 |
		arrow-cat |
		tail -3

}

ex2_native() {
	echo
	echo example 2 using sql
	jq -c -n \
		'[
		{timestamp:"2025-10-30T23:49:03.012345Z",severity:"INFO",status:200,body:"apt update done"},
		{timestamp:"2025-10-29T23:49:03.012345Z",severity:"INFO",status:200,body:"apt update done"},
		{timestamp:"2025-10-29T23:49:03.012345Z",severity:"INFO",status:200.0,body:"apt update done"},
		{timestamp:"2025-10-28T23:49:03.012345Z",severity:"WARN",status:500,body:"apt update failure"}
	]' |
		jq -c '.[]' |
		./rs-jsons2arrow-ipc-stream --num-lines 3 |
		rs-ipc-stream2df \
			--max-rows 1024 \
			--tabname 'jsons' \
			--sql "
			SELECT
			  *
			FROM jsons
			WHERE status=200
			ORDER BY timestamp
		" |
		rs-arrow-ipc-stream-cat
}

ex3_wasi() {
	echo
	echo 'example 3 using wazero & sql'
	jq -c -n \
		'[
		{timestamp:"2025-10-30T23:49:03.012345Z",severity:"INFO",status:200,body:"apt update done"},
		{timestamp:"2025-10-29T23:49:03.012345Z",severity:"INFO",status:200,body:"apt update done"},
		{timestamp:"2025-10-29T23:49:03.012345Z",severity:"INFO",status:200.0,body:"apt update done"},
		{timestamp:"2025-10-28T23:49:03.012345Z",severity:"WARN",status:500,body:"apt update failure"}
	]' |
		jq -c '.[]' |
		wazero run ./rs-jsons2arrow-ipc-stream.wasm -- --num-lines 2 |
		rs-ipc-stream2df \
			--max-rows 1024 \
			--tabname 'jsons' \
			--sql "
			SELECT
			  *
			FROM jsons
			WHERE status=200
			ORDER BY timestamp
		" |
		rs-arrow-ipc-stream-cat
}

ex1_native
ex2_native
ex3_wasi
