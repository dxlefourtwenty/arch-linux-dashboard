BUILD_DIR ?= build

compile:
	@if [ -f "$(BUILD_DIR)/CMakeCache.txt" ] && ! grep -q "CMAKE_HOME_DIRECTORY:INTERNAL=$(CURDIR)" "$(BUILD_DIR)/CMakeCache.txt"; then \
		rm -rf "$(BUILD_DIR)/CMakeCache.txt" "$(BUILD_DIR)/CMakeFiles"; \
	fi
	cmake -S . -B "$(BUILD_DIR)"
	cmake --build "$(BUILD_DIR)"
