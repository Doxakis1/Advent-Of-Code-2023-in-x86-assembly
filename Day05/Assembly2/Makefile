NAME = exec
AS=nasm
LD=ld
ASFLAGS=-f elf32
LDFLAGS=-m elf_i386

all: $(NAME)

SOURCE_FILES := $(wildcard *.asm)

OBJECT_FILES := $(SOURCE_FILES:.asm=.o)

$(NAME): $(OBJECT_FILES)
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.asm
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -f exec *.o
