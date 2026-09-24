CC = gcc
CFLAGS = -O3 -Wall -Wextra
LIBS = -lwayland-client -lm

TARGET = asus_ambilight
SRCS = asus_ambilight.c wlr-screencopy-protocol.c

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRCS) $(LIBS)

clean:
	rm -f $(TARGET)

.PHONY: all clean
