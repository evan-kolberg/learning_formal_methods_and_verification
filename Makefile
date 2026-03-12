all:
	@echo "Use 'make menu' to choose a target."

menu:
	@bash ./run_menu.sh

clean:
	rm -rf build