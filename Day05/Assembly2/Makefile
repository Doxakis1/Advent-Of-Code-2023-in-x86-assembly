AS=nasm
LD=ld
ASFLAGS=-f elf32
LDFLAGS=-m elf_i386

all: exec

exec: exec.o
	$(LD) $(LDFLAGS) -o $@ $^

exec.o: main.asm
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -f exec exec.o
