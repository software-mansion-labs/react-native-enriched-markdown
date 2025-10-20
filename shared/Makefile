# Makefile for MD4C test
CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -I./MD4C/src
LDFLAGS = 

# Source files (from submodule)
MD4C_SOURCES = MD4C/src/md4c.c MD4C/src/entity.c
TEST_SOURCE = test_md4c.c

# Target
TARGET = test_md4c

# Default target
all: $(TARGET)

# Build the test executable
$(TARGET): $(TEST_SOURCE) $(MD4C_SOURCES)
	$(CC) $(CFLAGS) -o $(TARGET) $(TEST_SOURCE) $(MD4C_SOURCES) $(LDFLAGS)

# Run the test
test: $(TARGET)
	./$(TARGET)

# Clean up
clean:
	rm -f $(TARGET)

# Help target
help:
	@echo "Available targets:"
	@echo "  all     - Build the test executable"
	@echo "  test    - Build and run the test"
	@echo "  clean   - Remove build artifacts"
	@echo "  help    - Show this help message"

.PHONY: all test clean help
