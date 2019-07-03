all: base

base: base.p4
	p4c-bm2-ss --arch v1model -o p4c-out/base.json --p4runtime-files p4c-out/base_p4info.txt base.p4

clean:
	rm -rf p4c-out/*
