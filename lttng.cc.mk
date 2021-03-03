# lttng.cc.mk

.PHONY:: lttng.cc.*

CLANG_VERSION ?= 12

LTTNG_PACKAGES = userspace-rcu lttng-ust lttng-tools babeltrace

lttng.cc.clang-upgrade: # upgrade clang version
	$(TRACE)
	$(MAKE) lttng.start
	$(call run-docker-exec, -t, sh -c "apt install -y wget lsb software-properties-common ")
	$(call run-docker-exec, -t, sh -c "wget https://apt.llvm.org/llvm.sh; chmod +x llvm.sh")
	$(call run-docker-exec, -t, sh -c "./llvm.sh $(CLANG_VERSION)")
	$(MKSTAMP)

lttng.cc.aptinstall: # install clang and other packages required to build codechecker
	$(TRACE)
	$(MAKE) lttng.start
	$(call run-docker-exec, -t, sh -c "apt update; apt upgrade -y")
	$(call run-docker-exec, -t, sh -c "apt install -y wget lsb software-properties-common")
	$(call run-docker-exec, -t, sh -c "apt install -y clang-format clang-tidy clang-tools clang clangd libc++-dev libc++1 libc++abi-dev libc++abi1 libclang-dev libclang1 liblldb-dev libllvm-ocaml-dev libomp-dev libomp5 lld lldb llvm-dev llvm-runtime llvm python-clang")
	$(call run-docker-exec, -t, sh -c "apt install -y build-essential curl doxygen gcc-multilib git python3-venv python3-dev")
	$(MKSTAMP)

lttng.cc.nodejs: # install nodejs required for CodeChecker
	$(TRACE)
	$(MAKE) lttng.start
	$(call run-docker-exec, -t, sh -c "curl -sL https://deb.nodesource.com/setup_12.x | bash -")
	$(call run-docker-exec, -t, sh -c "apt install -y nodejs")
	$(MKSTAMP)

lttng.cc.build: lttng.cc.aptinstall lttng.cc.nodejs # build CodeChecker
	$(TRACE)
	$(call run-docker-exec, -t, sh -c "if [ ! -e ~/codechecker ]; then git clone https://github.com/Ericsson/CodeChecker.git --depth 1 ~/codechecker; fi")
	$(call run-docker-exec, -it, sh -c "cd ~/codechecker; make venv")
	$(call run-docker-exec, -it, bash -c "cd ~/codechecker; source venv/bin/activate; make package")
	$(MKSTAMP)

lttng.cc.clean: # remove codechecker from docker image
	$(TRACE)
	-$(call run-docker-exec, -t, sh -c "rm -rf ~/codechecker")
	-$(call rmstamp,lttng.cc.nodejs)
	-$(call rmstamp,lttng.cc.aptinstall)
	-$(call rmstamp,lttng.cc.clang-upgrade)
	-$(call rmstamp,lttng.cc.build)

CCOPT ?= 0
lttng.cc.%: lttng.cc.build # run codechecker for package %
	$(TRACE)
	$(DOCKER) cp lttng/codechecker.sh $(LTTNG_CONTAINER):/root/codechecker.sh
	$(call run-docker-exec, -t, bash -c "/root/codechecker.sh $* $(CCOPT)")

lttng.cc.all: # run codechecker on all lttng packages
	$(TRACE)
	$(foreach package, $(LTTNG_PACKAGES), make -s lttng.cc.$(package); )

lttng.cc.ALL: # run codechecker on all lttng packages with 3 different options
	$(TRACE)
	$(foreach ccopt, 0 1 2, make -s lttng.cc.all CCOPT=$(ccopt); )

lttng.cc.help:
	$(TRACE)
	$(call run-help, lttng.cc.mk)
	$(call run-note, "- avalable packages are: $(LTTNG_PACKAGES)" )
	$(call run-note, "- CLANG_VERSION = $(CLANG_VERSION)" )

################################################################
