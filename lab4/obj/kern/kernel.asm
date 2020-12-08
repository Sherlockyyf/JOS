
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 30 11 00       	mov    $0x113000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 03 01 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010004c:	81 c3 bc 22 01 00    	add    $0x122bc,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 40 11 f0    	mov    $0xf0114060,%edx
f0100058:	c7 c0 a0 46 11 f0    	mov    $0xf01146a0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 7f 16 00 00       	call   f01016e8 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 38 f8 fe ff    	lea    -0x107c8(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 06 0b 00 00       	call   f0100b88 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 32 09 00 00       	call   f01009b9 <mem_init>
f0100087:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 8c 07 00 00       	call   f0100820 <monitor>
f0100094:	83 c4 10             	add    $0x10,%esp
f0100097:	eb f1                	jmp    f010008a <i386_init+0x4a>

f0100099 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100099:	55                   	push   %ebp
f010009a:	89 e5                	mov    %esp,%ebp
f010009c:	57                   	push   %edi
f010009d:	56                   	push   %esi
f010009e:	53                   	push   %ebx
f010009f:	83 ec 0c             	sub    $0xc,%esp
f01000a2:	e8 a8 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f01000a7:	81 c3 61 22 01 00    	add    $0x12261,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 a4 46 11 f0    	mov    $0xf01146a4,%eax
f01000b6:	83 38 00             	cmpl   $0x0,(%eax)
f01000b9:	74 0f                	je     f01000ca <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000bb:	83 ec 0c             	sub    $0xc,%esp
f01000be:	6a 00                	push   $0x0
f01000c0:	e8 5b 07 00 00       	call   f0100820 <monitor>
f01000c5:	83 c4 10             	add    $0x10,%esp
f01000c8:	eb f1                	jmp    f01000bb <_panic+0x22>
	panicstr = fmt;
f01000ca:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000cc:	fa                   	cli    
f01000cd:	fc                   	cld    
	va_start(ap, fmt);
f01000ce:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d1:	83 ec 04             	sub    $0x4,%esp
f01000d4:	ff 75 0c             	pushl  0xc(%ebp)
f01000d7:	ff 75 08             	pushl  0x8(%ebp)
f01000da:	8d 83 53 f8 fe ff    	lea    -0x107ad(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 a2 0a 00 00       	call   f0100b88 <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 61 0a 00 00       	call   f0100b51 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 8f f8 fe ff    	lea    -0x10771(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 8a 0a 00 00       	call   f0100b88 <cprintf>
f01000fe:	83 c4 10             	add    $0x10,%esp
f0100101:	eb b8                	jmp    f01000bb <_panic+0x22>

f0100103 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100103:	55                   	push   %ebp
f0100104:	89 e5                	mov    %esp,%ebp
f0100106:	56                   	push   %esi
f0100107:	53                   	push   %ebx
f0100108:	e8 42 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010010d:	81 c3 fb 21 01 00    	add    $0x121fb,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 6b f8 fe ff    	lea    -0x10795(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 5d 0a 00 00       	call   f0100b88 <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 1a 0a 00 00       	call   f0100b51 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 8f f8 fe ff    	lea    -0x10771(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 43 0a 00 00       	call   f0100b88 <cprintf>
	va_end(ap);
}
f0100145:	83 c4 10             	add    $0x10,%esp
f0100148:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010014b:	5b                   	pop    %ebx
f010014c:	5e                   	pop    %esi
f010014d:	5d                   	pop    %ebp
f010014e:	c3                   	ret    

f010014f <__x86.get_pc_thunk.bx>:
f010014f:	8b 1c 24             	mov    (%esp),%ebx
f0100152:	c3                   	ret    

f0100153 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100153:	55                   	push   %ebp
f0100154:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100156:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010015b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 0b                	je     f010016b <serial_proc_data+0x18>
f0100160:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100165:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100166:	0f b6 c0             	movzbl %al,%eax
}
f0100169:	5d                   	pop    %ebp
f010016a:	c3                   	ret    
		return -1;
f010016b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100170:	eb f7                	jmp    f0100169 <serial_proc_data+0x16>

f0100172 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100172:	55                   	push   %ebp
f0100173:	89 e5                	mov    %esp,%ebp
f0100175:	56                   	push   %esi
f0100176:	53                   	push   %ebx
f0100177:	e8 d3 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010017c:	81 c3 8c 21 01 00    	add    $0x1218c,%ebx
f0100182:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f0100184:	ff d6                	call   *%esi
f0100186:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100189:	74 2e                	je     f01001b9 <cons_intr+0x47>
		if (c == 0)
f010018b:	85 c0                	test   %eax,%eax
f010018d:	74 f5                	je     f0100184 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f010018f:	8b 8b 7c 1f 00 00    	mov    0x1f7c(%ebx),%ecx
f0100195:	8d 51 01             	lea    0x1(%ecx),%edx
f0100198:	89 93 7c 1f 00 00    	mov    %edx,0x1f7c(%ebx)
f010019e:	88 84 0b 78 1d 00 00 	mov    %al,0x1d78(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ab:	75 d7                	jne    f0100184 <cons_intr+0x12>
			cons.wpos = 0;
f01001ad:	c7 83 7c 1f 00 00 00 	movl   $0x0,0x1f7c(%ebx)
f01001b4:	00 00 00 
f01001b7:	eb cb                	jmp    f0100184 <cons_intr+0x12>
	}
}
f01001b9:	5b                   	pop    %ebx
f01001ba:	5e                   	pop    %esi
f01001bb:	5d                   	pop    %ebp
f01001bc:	c3                   	ret    

f01001bd <kbd_proc_data>:
{
f01001bd:	55                   	push   %ebp
f01001be:	89 e5                	mov    %esp,%ebp
f01001c0:	56                   	push   %esi
f01001c1:	53                   	push   %ebx
f01001c2:	e8 88 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01001c7:	81 c3 41 21 01 00    	add    $0x12141,%ebx
f01001cd:	ba 64 00 00 00       	mov    $0x64,%edx
f01001d2:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001d3:	a8 01                	test   $0x1,%al
f01001d5:	0f 84 06 01 00 00    	je     f01002e1 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f01001db:	a8 20                	test   $0x20,%al
f01001dd:	0f 85 05 01 00 00    	jne    f01002e8 <kbd_proc_data+0x12b>
f01001e3:	ba 60 00 00 00       	mov    $0x60,%edx
f01001e8:	ec                   	in     (%dx),%al
f01001e9:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001eb:	3c e0                	cmp    $0xe0,%al
f01001ed:	0f 84 93 00 00 00    	je     f0100286 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f01001f3:	84 c0                	test   %al,%al
f01001f5:	0f 88 a0 00 00 00    	js     f010029b <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f01001fb:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x57>
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 8b 58 1d 00 00    	mov    %ecx,0x1d58(%ebx)
	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
f0100217:	0f b6 84 13 b8 f9 fe 	movzbl -0x10648(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 b8 f8 fe 	movzbl -0x10748(%ebx,%edx,1),%ecx
f010022c:	ff 
f010022d:	31 c8                	xor    %ecx,%eax
f010022f:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100235:	89 c1                	mov    %eax,%ecx
f0100237:	83 e1 03             	and    $0x3,%ecx
f010023a:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f0100241:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100245:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100248:	a8 08                	test   $0x8,%al
f010024a:	74 0d                	je     f0100259 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f010024c:	89 f2                	mov    %esi,%edx
f010024e:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100251:	83 f9 19             	cmp    $0x19,%ecx
f0100254:	77 7a                	ja     f01002d0 <kbd_proc_data+0x113>
			c += 'A' - 'a';
f0100256:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100259:	f7 d0                	not    %eax
f010025b:	a8 06                	test   $0x6,%al
f010025d:	75 33                	jne    f0100292 <kbd_proc_data+0xd5>
f010025f:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f0100265:	75 2b                	jne    f0100292 <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f0100267:	83 ec 0c             	sub    $0xc,%esp
f010026a:	8d 83 85 f8 fe ff    	lea    -0x1077b(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 12 09 00 00       	call   f0100b88 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100276:	b8 03 00 00 00       	mov    $0x3,%eax
f010027b:	ba 92 00 00 00       	mov    $0x92,%edx
f0100280:	ee                   	out    %al,(%dx)
f0100281:	83 c4 10             	add    $0x10,%esp
f0100284:	eb 0c                	jmp    f0100292 <kbd_proc_data+0xd5>
		shift |= E0ESC;
f0100286:	83 8b 58 1d 00 00 40 	orl    $0x40,0x1d58(%ebx)
		return 0;
f010028d:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100292:	89 f0                	mov    %esi,%eax
f0100294:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100297:	5b                   	pop    %ebx
f0100298:	5e                   	pop    %esi
f0100299:	5d                   	pop    %ebp
f010029a:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010029b:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f01002a1:	89 ce                	mov    %ecx,%esi
f01002a3:	83 e6 40             	and    $0x40,%esi
f01002a6:	83 e0 7f             	and    $0x7f,%eax
f01002a9:	85 f6                	test   %esi,%esi
f01002ab:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002ae:	0f b6 d2             	movzbl %dl,%edx
f01002b1:	0f b6 84 13 b8 f9 fe 	movzbl -0x10648(%ebx,%edx,1),%eax
f01002b8:	ff 
f01002b9:	83 c8 40             	or     $0x40,%eax
f01002bc:	0f b6 c0             	movzbl %al,%eax
f01002bf:	f7 d0                	not    %eax
f01002c1:	21 c8                	and    %ecx,%eax
f01002c3:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
		return 0;
f01002c9:	be 00 00 00 00       	mov    $0x0,%esi
f01002ce:	eb c2                	jmp    f0100292 <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f01002d0:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002d3:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002d6:	83 fa 1a             	cmp    $0x1a,%edx
f01002d9:	0f 42 f1             	cmovb  %ecx,%esi
f01002dc:	e9 78 ff ff ff       	jmp    f0100259 <kbd_proc_data+0x9c>
		return -1;
f01002e1:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002e6:	eb aa                	jmp    f0100292 <kbd_proc_data+0xd5>
		return -1;
f01002e8:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002ed:	eb a3                	jmp    f0100292 <kbd_proc_data+0xd5>

f01002ef <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ef:	55                   	push   %ebp
f01002f0:	89 e5                	mov    %esp,%ebp
f01002f2:	57                   	push   %edi
f01002f3:	56                   	push   %esi
f01002f4:	53                   	push   %ebx
f01002f5:	83 ec 1c             	sub    $0x1c,%esp
f01002f8:	e8 52 fe ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01002fd:	81 c3 0b 20 01 00    	add    $0x1200b,%ebx
f0100303:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100306:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030b:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100310:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100315:	eb 09                	jmp    f0100320 <cons_putc+0x31>
f0100317:	89 ca                	mov    %ecx,%edx
f0100319:	ec                   	in     (%dx),%al
f010031a:	ec                   	in     (%dx),%al
f010031b:	ec                   	in     (%dx),%al
f010031c:	ec                   	in     (%dx),%al
	     i++)
f010031d:	83 c6 01             	add    $0x1,%esi
f0100320:	89 fa                	mov    %edi,%edx
f0100322:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100323:	a8 20                	test   $0x20,%al
f0100325:	75 08                	jne    f010032f <cons_putc+0x40>
f0100327:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010032d:	7e e8                	jle    f0100317 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f010032f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100332:	89 f8                	mov    %edi,%eax
f0100334:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100337:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010033c:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010033d:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100342:	bf 79 03 00 00       	mov    $0x379,%edi
f0100347:	b9 84 00 00 00       	mov    $0x84,%ecx
f010034c:	eb 09                	jmp    f0100357 <cons_putc+0x68>
f010034e:	89 ca                	mov    %ecx,%edx
f0100350:	ec                   	in     (%dx),%al
f0100351:	ec                   	in     (%dx),%al
f0100352:	ec                   	in     (%dx),%al
f0100353:	ec                   	in     (%dx),%al
f0100354:	83 c6 01             	add    $0x1,%esi
f0100357:	89 fa                	mov    %edi,%edx
f0100359:	ec                   	in     (%dx),%al
f010035a:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100360:	7f 04                	jg     f0100366 <cons_putc+0x77>
f0100362:	84 c0                	test   %al,%al
f0100364:	79 e8                	jns    f010034e <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100366:	ba 78 03 00 00       	mov    $0x378,%edx
f010036b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f010036f:	ee                   	out    %al,(%dx)
f0100370:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100375:	b8 0d 00 00 00       	mov    $0xd,%eax
f010037a:	ee                   	out    %al,(%dx)
f010037b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100380:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100381:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100384:	89 fa                	mov    %edi,%edx
f0100386:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010038c:	89 f8                	mov    %edi,%eax
f010038e:	80 cc 07             	or     $0x7,%ah
f0100391:	85 d2                	test   %edx,%edx
f0100393:	0f 45 c7             	cmovne %edi,%eax
f0100396:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100399:	0f b6 c0             	movzbl %al,%eax
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	0f 84 b9 00 00 00    	je     f010045e <cons_putc+0x16f>
f01003a5:	83 f8 09             	cmp    $0x9,%eax
f01003a8:	7e 74                	jle    f010041e <cons_putc+0x12f>
f01003aa:	83 f8 0a             	cmp    $0xa,%eax
f01003ad:	0f 84 9e 00 00 00    	je     f0100451 <cons_putc+0x162>
f01003b3:	83 f8 0d             	cmp    $0xd,%eax
f01003b6:	0f 85 d9 00 00 00    	jne    f0100495 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f01003bc:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f01003c3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c9:	c1 e8 16             	shr    $0x16,%eax
f01003cc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003cf:	c1 e0 04             	shl    $0x4,%eax
f01003d2:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003d9:	66 81 bb 80 1f 00 00 	cmpw   $0x7cf,0x1f80(%ebx)
f01003e0:	cf 07 
f01003e2:	0f 87 d4 00 00 00    	ja     f01004bc <cons_putc+0x1cd>
	outb(addr_6845, 14);
f01003e8:	8b 8b 88 1f 00 00    	mov    0x1f88(%ebx),%ecx
f01003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003f3:	89 ca                	mov    %ecx,%edx
f01003f5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003f6:	0f b7 9b 80 1f 00 00 	movzwl 0x1f80(%ebx),%ebx
f01003fd:	8d 71 01             	lea    0x1(%ecx),%esi
f0100400:	89 d8                	mov    %ebx,%eax
f0100402:	66 c1 e8 08          	shr    $0x8,%ax
f0100406:	89 f2                	mov    %esi,%edx
f0100408:	ee                   	out    %al,(%dx)
f0100409:	b8 0f 00 00 00       	mov    $0xf,%eax
f010040e:	89 ca                	mov    %ecx,%edx
f0100410:	ee                   	out    %al,(%dx)
f0100411:	89 d8                	mov    %ebx,%eax
f0100413:	89 f2                	mov    %esi,%edx
f0100415:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100416:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100419:	5b                   	pop    %ebx
f010041a:	5e                   	pop    %esi
f010041b:	5f                   	pop    %edi
f010041c:	5d                   	pop    %ebp
f010041d:	c3                   	ret    
	switch (c & 0xff) {
f010041e:	83 f8 08             	cmp    $0x8,%eax
f0100421:	75 72                	jne    f0100495 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f0100423:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010042a:	66 85 c0             	test   %ax,%ax
f010042d:	74 b9                	je     f01003e8 <cons_putc+0xf9>
			crt_pos--;
f010042f:	83 e8 01             	sub    $0x1,%eax
f0100432:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100440:	b2 00                	mov    $0x0,%dl
f0100442:	83 ca 20             	or     $0x20,%edx
f0100445:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f010044b:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010044f:	eb 88                	jmp    f01003d9 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100451:	66 83 83 80 1f 00 00 	addw   $0x50,0x1f80(%ebx)
f0100458:	50 
f0100459:	e9 5e ff ff ff       	jmp    f01003bc <cons_putc+0xcd>
		cons_putc(' ');
f010045e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100463:	e8 87 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100468:	b8 20 00 00 00       	mov    $0x20,%eax
f010046d:	e8 7d fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100472:	b8 20 00 00 00       	mov    $0x20,%eax
f0100477:	e8 73 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f010047c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100481:	e8 69 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100486:	b8 20 00 00 00       	mov    $0x20,%eax
f010048b:	e8 5f fe ff ff       	call   f01002ef <cons_putc>
f0100490:	e9 44 ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100495:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010049c:	8d 50 01             	lea    0x1(%eax),%edx
f010049f:	66 89 93 80 1f 00 00 	mov    %dx,0x1f80(%ebx)
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f01004af:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004b3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b7:	e9 1d ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004bc:	8b 83 84 1f 00 00    	mov    0x1f84(%ebx),%eax
f01004c2:	83 ec 04             	sub    $0x4,%esp
f01004c5:	68 00 0f 00 00       	push   $0xf00
f01004ca:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d0:	52                   	push   %edx
f01004d1:	50                   	push   %eax
f01004d2:	e8 5e 12 00 00       	call   f0101735 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004d7:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f01004dd:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004e3:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004e9:	83 c4 10             	add    $0x10,%esp
f01004ec:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004f1:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f4:	39 d0                	cmp    %edx,%eax
f01004f6:	75 f4                	jne    f01004ec <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f01004f8:	66 83 ab 80 1f 00 00 	subw   $0x50,0x1f80(%ebx)
f01004ff:	50 
f0100500:	e9 e3 fe ff ff       	jmp    f01003e8 <cons_putc+0xf9>

f0100505 <serial_intr>:
{
f0100505:	e8 e7 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010050a:	05 fe 1d 01 00       	add    $0x11dfe,%eax
	if (serial_exists)
f010050f:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 4b de fe ff    	lea    -0x121b5(%eax),%eax
f0100526:	e8 47 fc ff ff       	call   f0100172 <cons_intr>
}
f010052b:	c9                   	leave  
f010052c:	c3                   	ret    

f010052d <kbd_intr>:
{
f010052d:	55                   	push   %ebp
f010052e:	89 e5                	mov    %esp,%ebp
f0100530:	83 ec 08             	sub    $0x8,%esp
f0100533:	e8 b9 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0100538:	05 d0 1d 01 00       	add    $0x11dd0,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b5 de fe ff    	lea    -0x1214b(%eax),%eax
f0100543:	e8 2a fc ff ff       	call   f0100172 <cons_intr>
}
f0100548:	c9                   	leave  
f0100549:	c3                   	ret    

f010054a <cons_getc>:
{
f010054a:	55                   	push   %ebp
f010054b:	89 e5                	mov    %esp,%ebp
f010054d:	53                   	push   %ebx
f010054e:	83 ec 04             	sub    $0x4,%esp
f0100551:	e8 f9 fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100556:	81 c3 b2 1d 01 00    	add    $0x11db2,%ebx
	serial_intr();
f010055c:	e8 a4 ff ff ff       	call   f0100505 <serial_intr>
	kbd_intr();
f0100561:	e8 c7 ff ff ff       	call   f010052d <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100566:	8b 93 78 1f 00 00    	mov    0x1f78(%ebx),%edx
	return 0;
f010056c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100571:	3b 93 7c 1f 00 00    	cmp    0x1f7c(%ebx),%edx
f0100577:	74 19                	je     f0100592 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100579:	8d 4a 01             	lea    0x1(%edx),%ecx
f010057c:	89 8b 78 1f 00 00    	mov    %ecx,0x1f78(%ebx)
f0100582:	0f b6 84 13 78 1d 00 	movzbl 0x1d78(%ebx,%edx,1),%eax
f0100589:	00 
		if (cons.rpos == CONSBUFSIZE)
f010058a:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100590:	74 06                	je     f0100598 <cons_getc+0x4e>
}
f0100592:	83 c4 04             	add    $0x4,%esp
f0100595:	5b                   	pop    %ebx
f0100596:	5d                   	pop    %ebp
f0100597:	c3                   	ret    
			cons.rpos = 0;
f0100598:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
f010059f:	00 00 00 
f01005a2:	eb ee                	jmp    f0100592 <cons_getc+0x48>

f01005a4 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005a4:	55                   	push   %ebp
f01005a5:	89 e5                	mov    %esp,%ebp
f01005a7:	57                   	push   %edi
f01005a8:	56                   	push   %esi
f01005a9:	53                   	push   %ebx
f01005aa:	83 ec 1c             	sub    $0x1c,%esp
f01005ad:	e8 9d fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01005b2:	81 c3 56 1d 01 00    	add    $0x11d56,%ebx
	was = *cp;
f01005b8:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005bf:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005c6:	5a a5 
	if (*cp != 0xA55A) {
f01005c8:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005cf:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005d3:	0f 84 bc 00 00 00    	je     f0100695 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01005d9:	c7 83 88 1f 00 00 b4 	movl   $0x3b4,0x1f88(%ebx)
f01005e0:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005e3:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01005ea:	8b bb 88 1f 00 00    	mov    0x1f88(%ebx),%edi
f01005f0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005f5:	89 fa                	mov    %edi,%edx
f01005f7:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005f8:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005fb:	89 ca                	mov    %ecx,%edx
f01005fd:	ec                   	in     (%dx),%al
f01005fe:	0f b6 f0             	movzbl %al,%esi
f0100601:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100604:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100609:	89 fa                	mov    %edi,%edx
f010060b:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010060c:	89 ca                	mov    %ecx,%edx
f010060e:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010060f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100612:	89 bb 84 1f 00 00    	mov    %edi,0x1f84(%ebx)
	pos |= inb(addr_6845 + 1);
f0100618:	0f b6 c0             	movzbl %al,%eax
f010061b:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010061d:	66 89 b3 80 1f 00 00 	mov    %si,0x1f80(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100624:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100629:	89 c8                	mov    %ecx,%eax
f010062b:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100630:	ee                   	out    %al,(%dx)
f0100631:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100636:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010063b:	89 fa                	mov    %edi,%edx
f010063d:	ee                   	out    %al,(%dx)
f010063e:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100643:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100648:	ee                   	out    %al,(%dx)
f0100649:	be f9 03 00 00       	mov    $0x3f9,%esi
f010064e:	89 c8                	mov    %ecx,%eax
f0100650:	89 f2                	mov    %esi,%edx
f0100652:	ee                   	out    %al,(%dx)
f0100653:	b8 03 00 00 00       	mov    $0x3,%eax
f0100658:	89 fa                	mov    %edi,%edx
f010065a:	ee                   	out    %al,(%dx)
f010065b:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100660:	89 c8                	mov    %ecx,%eax
f0100662:	ee                   	out    %al,(%dx)
f0100663:	b8 01 00 00 00       	mov    $0x1,%eax
f0100668:	89 f2                	mov    %esi,%edx
f010066a:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010066b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100670:	ec                   	in     (%dx),%al
f0100671:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100673:	3c ff                	cmp    $0xff,%al
f0100675:	0f 95 83 8c 1f 00 00 	setne  0x1f8c(%ebx)
f010067c:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100681:	ec                   	in     (%dx),%al
f0100682:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100687:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100688:	80 f9 ff             	cmp    $0xff,%cl
f010068b:	74 25                	je     f01006b2 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f010068d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100690:	5b                   	pop    %ebx
f0100691:	5e                   	pop    %esi
f0100692:	5f                   	pop    %edi
f0100693:	5d                   	pop    %ebp
f0100694:	c3                   	ret    
		*cp = was;
f0100695:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010069c:	c7 83 88 1f 00 00 d4 	movl   $0x3d4,0x1f88(%ebx)
f01006a3:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a6:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006ad:	e9 38 ff ff ff       	jmp    f01005ea <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006b2:	83 ec 0c             	sub    $0xc,%esp
f01006b5:	8d 83 91 f8 fe ff    	lea    -0x1076f(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 c7 04 00 00       	call   f0100b88 <cprintf>
f01006c1:	83 c4 10             	add    $0x10,%esp
}
f01006c4:	eb c7                	jmp    f010068d <cons_init+0xe9>

f01006c6 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006c6:	55                   	push   %ebp
f01006c7:	89 e5                	mov    %esp,%ebp
f01006c9:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01006cf:	e8 1b fc ff ff       	call   f01002ef <cons_putc>
}
f01006d4:	c9                   	leave  
f01006d5:	c3                   	ret    

f01006d6 <getchar>:

int
getchar(void)
{
f01006d6:	55                   	push   %ebp
f01006d7:	89 e5                	mov    %esp,%ebp
f01006d9:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006dc:	e8 69 fe ff ff       	call   f010054a <cons_getc>
f01006e1:	85 c0                	test   %eax,%eax
f01006e3:	74 f7                	je     f01006dc <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006e5:	c9                   	leave  
f01006e6:	c3                   	ret    

f01006e7 <iscons>:

int
iscons(int fdnum)
{
f01006e7:	55                   	push   %ebp
f01006e8:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01006ef:	5d                   	pop    %ebp
f01006f0:	c3                   	ret    

f01006f1 <__x86.get_pc_thunk.ax>:
f01006f1:	8b 04 24             	mov    (%esp),%eax
f01006f4:	c3                   	ret    

f01006f5 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006f5:	55                   	push   %ebp
f01006f6:	89 e5                	mov    %esp,%ebp
f01006f8:	56                   	push   %esi
f01006f9:	53                   	push   %ebx
f01006fa:	e8 50 fa ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01006ff:	81 c3 09 1c 01 00    	add    $0x11c09,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 b8 fa fe ff    	lea    -0x10548(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 d6 fa fe ff    	lea    -0x1052a(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 db fa fe ff    	lea    -0x10525(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 66 04 00 00       	call   f0100b88 <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 44 fb fe ff    	lea    -0x104bc(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 e4 fa fe ff    	lea    -0x1051c(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 4f 04 00 00       	call   f0100b88 <cprintf>
	return 0;
}
f0100739:	b8 00 00 00 00       	mov    $0x0,%eax
f010073e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100741:	5b                   	pop    %ebx
f0100742:	5e                   	pop    %esi
f0100743:	5d                   	pop    %ebp
f0100744:	c3                   	ret    

f0100745 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100745:	55                   	push   %ebp
f0100746:	89 e5                	mov    %esp,%ebp
f0100748:	57                   	push   %edi
f0100749:	56                   	push   %esi
f010074a:	53                   	push   %ebx
f010074b:	83 ec 18             	sub    $0x18,%esp
f010074e:	e8 fc f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100753:	81 c3 b5 1b 01 00    	add    $0x11bb5,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100759:	8d 83 ed fa fe ff    	lea    -0x10513(%ebx),%eax
f010075f:	50                   	push   %eax
f0100760:	e8 23 04 00 00       	call   f0100b88 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100765:	83 c4 08             	add    $0x8,%esp
f0100768:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010076e:	8d 83 6c fb fe ff    	lea    -0x10494(%ebx),%eax
f0100774:	50                   	push   %eax
f0100775:	e8 0e 04 00 00       	call   f0100b88 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010077a:	83 c4 0c             	add    $0xc,%esp
f010077d:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100783:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100789:	50                   	push   %eax
f010078a:	57                   	push   %edi
f010078b:	8d 83 94 fb fe ff    	lea    -0x1046c(%ebx),%eax
f0100791:	50                   	push   %eax
f0100792:	e8 f1 03 00 00       	call   f0100b88 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100797:	83 c4 0c             	add    $0xc,%esp
f010079a:	c7 c0 29 1b 10 f0    	mov    $0xf0101b29,%eax
f01007a0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007a6:	52                   	push   %edx
f01007a7:	50                   	push   %eax
f01007a8:	8d 83 b8 fb fe ff    	lea    -0x10448(%ebx),%eax
f01007ae:	50                   	push   %eax
f01007af:	e8 d4 03 00 00       	call   f0100b88 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007b4:	83 c4 0c             	add    $0xc,%esp
f01007b7:	c7 c0 60 40 11 f0    	mov    $0xf0114060,%eax
f01007bd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007c3:	52                   	push   %edx
f01007c4:	50                   	push   %eax
f01007c5:	8d 83 dc fb fe ff    	lea    -0x10424(%ebx),%eax
f01007cb:	50                   	push   %eax
f01007cc:	e8 b7 03 00 00       	call   f0100b88 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007d1:	83 c4 0c             	add    $0xc,%esp
f01007d4:	c7 c6 a0 46 11 f0    	mov    $0xf01146a0,%esi
f01007da:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007e0:	50                   	push   %eax
f01007e1:	56                   	push   %esi
f01007e2:	8d 83 00 fc fe ff    	lea    -0x10400(%ebx),%eax
f01007e8:	50                   	push   %eax
f01007e9:	e8 9a 03 00 00       	call   f0100b88 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007ee:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007f1:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f01007f7:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f9:	c1 fe 0a             	sar    $0xa,%esi
f01007fc:	56                   	push   %esi
f01007fd:	8d 83 24 fc fe ff    	lea    -0x103dc(%ebx),%eax
f0100803:	50                   	push   %eax
f0100804:	e8 7f 03 00 00       	call   f0100b88 <cprintf>
	return 0;
}
f0100809:	b8 00 00 00 00       	mov    $0x0,%eax
f010080e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100811:	5b                   	pop    %ebx
f0100812:	5e                   	pop    %esi
f0100813:	5f                   	pop    %edi
f0100814:	5d                   	pop    %ebp
f0100815:	c3                   	ret    

f0100816 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100816:	55                   	push   %ebp
f0100817:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100819:	b8 00 00 00 00       	mov    $0x0,%eax
f010081e:	5d                   	pop    %ebp
f010081f:	c3                   	ret    

f0100820 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100820:	55                   	push   %ebp
f0100821:	89 e5                	mov    %esp,%ebp
f0100823:	57                   	push   %edi
f0100824:	56                   	push   %esi
f0100825:	53                   	push   %ebx
f0100826:	83 ec 68             	sub    $0x68,%esp
f0100829:	e8 21 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010082e:	81 c3 da 1a 01 00    	add    $0x11ada,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100834:	8d 83 50 fc fe ff    	lea    -0x103b0(%ebx),%eax
f010083a:	50                   	push   %eax
f010083b:	e8 48 03 00 00       	call   f0100b88 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100840:	8d 83 74 fc fe ff    	lea    -0x1038c(%ebx),%eax
f0100846:	89 04 24             	mov    %eax,(%esp)
f0100849:	e8 3a 03 00 00       	call   f0100b88 <cprintf>
f010084e:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100851:	8d bb 0a fb fe ff    	lea    -0x104f6(%ebx),%edi
f0100857:	eb 4a                	jmp    f01008a3 <monitor+0x83>
f0100859:	83 ec 08             	sub    $0x8,%esp
f010085c:	0f be c0             	movsbl %al,%eax
f010085f:	50                   	push   %eax
f0100860:	57                   	push   %edi
f0100861:	e8 45 0e 00 00       	call   f01016ab <strchr>
f0100866:	83 c4 10             	add    $0x10,%esp
f0100869:	85 c0                	test   %eax,%eax
f010086b:	74 08                	je     f0100875 <monitor+0x55>
			*buf++ = 0;
f010086d:	c6 06 00             	movb   $0x0,(%esi)
f0100870:	8d 76 01             	lea    0x1(%esi),%esi
f0100873:	eb 79                	jmp    f01008ee <monitor+0xce>
		if (*buf == 0)
f0100875:	80 3e 00             	cmpb   $0x0,(%esi)
f0100878:	74 7f                	je     f01008f9 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f010087a:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f010087e:	74 0f                	je     f010088f <monitor+0x6f>
		argv[argc++] = buf;
f0100880:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100883:	8d 48 01             	lea    0x1(%eax),%ecx
f0100886:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100889:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f010088d:	eb 44                	jmp    f01008d3 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010088f:	83 ec 08             	sub    $0x8,%esp
f0100892:	6a 10                	push   $0x10
f0100894:	8d 83 0f fb fe ff    	lea    -0x104f1(%ebx),%eax
f010089a:	50                   	push   %eax
f010089b:	e8 e8 02 00 00       	call   f0100b88 <cprintf>
f01008a0:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01008a3:	8d 83 06 fb fe ff    	lea    -0x104fa(%ebx),%eax
f01008a9:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01008ac:	83 ec 0c             	sub    $0xc,%esp
f01008af:	ff 75 a4             	pushl  -0x5c(%ebp)
f01008b2:	e8 bc 0b 00 00       	call   f0101473 <readline>
f01008b7:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01008b9:	83 c4 10             	add    $0x10,%esp
f01008bc:	85 c0                	test   %eax,%eax
f01008be:	74 ec                	je     f01008ac <monitor+0x8c>
	argv[argc] = 0;
f01008c0:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01008c7:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f01008ce:	eb 1e                	jmp    f01008ee <monitor+0xce>
			buf++;
f01008d0:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d3:	0f b6 06             	movzbl (%esi),%eax
f01008d6:	84 c0                	test   %al,%al
f01008d8:	74 14                	je     f01008ee <monitor+0xce>
f01008da:	83 ec 08             	sub    $0x8,%esp
f01008dd:	0f be c0             	movsbl %al,%eax
f01008e0:	50                   	push   %eax
f01008e1:	57                   	push   %edi
f01008e2:	e8 c4 0d 00 00       	call   f01016ab <strchr>
f01008e7:	83 c4 10             	add    $0x10,%esp
f01008ea:	85 c0                	test   %eax,%eax
f01008ec:	74 e2                	je     f01008d0 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f01008ee:	0f b6 06             	movzbl (%esi),%eax
f01008f1:	84 c0                	test   %al,%al
f01008f3:	0f 85 60 ff ff ff    	jne    f0100859 <monitor+0x39>
	argv[argc] = 0;
f01008f9:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01008fc:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100903:	00 
	if (argc == 0)
f0100904:	85 c0                	test   %eax,%eax
f0100906:	74 9b                	je     f01008a3 <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100908:	83 ec 08             	sub    $0x8,%esp
f010090b:	8d 83 d6 fa fe ff    	lea    -0x1052a(%ebx),%eax
f0100911:	50                   	push   %eax
f0100912:	ff 75 a8             	pushl  -0x58(%ebp)
f0100915:	e8 33 0d 00 00       	call   f010164d <strcmp>
f010091a:	83 c4 10             	add    $0x10,%esp
f010091d:	85 c0                	test   %eax,%eax
f010091f:	74 38                	je     f0100959 <monitor+0x139>
f0100921:	83 ec 08             	sub    $0x8,%esp
f0100924:	8d 83 e4 fa fe ff    	lea    -0x1051c(%ebx),%eax
f010092a:	50                   	push   %eax
f010092b:	ff 75 a8             	pushl  -0x58(%ebp)
f010092e:	e8 1a 0d 00 00       	call   f010164d <strcmp>
f0100933:	83 c4 10             	add    $0x10,%esp
f0100936:	85 c0                	test   %eax,%eax
f0100938:	74 1a                	je     f0100954 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f010093a:	83 ec 08             	sub    $0x8,%esp
f010093d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100940:	8d 83 2c fb fe ff    	lea    -0x104d4(%ebx),%eax
f0100946:	50                   	push   %eax
f0100947:	e8 3c 02 00 00       	call   f0100b88 <cprintf>
f010094c:	83 c4 10             	add    $0x10,%esp
f010094f:	e9 4f ff ff ff       	jmp    f01008a3 <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100954:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100959:	83 ec 04             	sub    $0x4,%esp
f010095c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010095f:	ff 75 08             	pushl  0x8(%ebp)
f0100962:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100965:	52                   	push   %edx
f0100966:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100969:	ff 94 83 10 1d 00 00 	call   *0x1d10(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100970:	83 c4 10             	add    $0x10,%esp
f0100973:	85 c0                	test   %eax,%eax
f0100975:	0f 89 28 ff ff ff    	jns    f01008a3 <monitor+0x83>
				break;
	}
}
f010097b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010097e:	5b                   	pop    %ebx
f010097f:	5e                   	pop    %esi
f0100980:	5f                   	pop    %edi
f0100981:	5d                   	pop    %ebp
f0100982:	c3                   	ret    

f0100983 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
f0100986:	57                   	push   %edi
f0100987:	56                   	push   %esi
f0100988:	53                   	push   %ebx
f0100989:	83 ec 18             	sub    $0x18,%esp
f010098c:	e8 be f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100991:	81 c3 77 19 01 00    	add    $0x11977,%ebx
f0100997:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100999:	50                   	push   %eax
f010099a:	e8 62 01 00 00       	call   f0100b01 <mc146818_read>
f010099f:	89 c6                	mov    %eax,%esi
f01009a1:	83 c7 01             	add    $0x1,%edi
f01009a4:	89 3c 24             	mov    %edi,(%esp)
f01009a7:	e8 55 01 00 00       	call   f0100b01 <mc146818_read>
f01009ac:	c1 e0 08             	shl    $0x8,%eax
f01009af:	09 f0                	or     %esi,%eax
}
f01009b1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009b4:	5b                   	pop    %ebx
f01009b5:	5e                   	pop    %esi
f01009b6:	5f                   	pop    %edi
f01009b7:	5d                   	pop    %ebp
f01009b8:	c3                   	ret    

f01009b9 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01009b9:	55                   	push   %ebp
f01009ba:	89 e5                	mov    %esp,%ebp
f01009bc:	57                   	push   %edi
f01009bd:	56                   	push   %esi
f01009be:	53                   	push   %ebx
f01009bf:	83 ec 0c             	sub    $0xc,%esp
f01009c2:	e8 88 f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01009c7:	81 c3 41 19 01 00    	add    $0x11941,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f01009cd:	b8 15 00 00 00       	mov    $0x15,%eax
f01009d2:	e8 ac ff ff ff       	call   f0100983 <nvram_read>
f01009d7:	89 c6                	mov    %eax,%esi
	extmem = nvram_read(NVRAM_EXTLO);
f01009d9:	b8 17 00 00 00       	mov    $0x17,%eax
f01009de:	e8 a0 ff ff ff       	call   f0100983 <nvram_read>
f01009e3:	89 c7                	mov    %eax,%edi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01009e5:	b8 34 00 00 00       	mov    $0x34,%eax
f01009ea:	e8 94 ff ff ff       	call   f0100983 <nvram_read>
f01009ef:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f01009f2:	85 c0                	test   %eax,%eax
f01009f4:	75 0e                	jne    f0100a04 <mem_init+0x4b>
		totalmem = basemem;
f01009f6:	89 f0                	mov    %esi,%eax
	else if (extmem)
f01009f8:	85 ff                	test   %edi,%edi
f01009fa:	74 0d                	je     f0100a09 <mem_init+0x50>
		totalmem = 1 * 1024 + extmem;
f01009fc:	8d 87 00 04 00 00    	lea    0x400(%edi),%eax
f0100a02:	eb 05                	jmp    f0100a09 <mem_init+0x50>
		totalmem = 16 * 1024 + ext16mem;
f0100a04:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f0100a09:	89 c1                	mov    %eax,%ecx
f0100a0b:	c1 e9 02             	shr    $0x2,%ecx
f0100a0e:	c7 c2 a8 46 11 f0    	mov    $0xf01146a8,%edx
f0100a14:	89 0a                	mov    %ecx,(%edx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a16:	89 c2                	mov    %eax,%edx
f0100a18:	29 f2                	sub    %esi,%edx
f0100a1a:	52                   	push   %edx
f0100a1b:	56                   	push   %esi
f0100a1c:	50                   	push   %eax
f0100a1d:	8d 83 9c fc fe ff    	lea    -0x10364(%ebx),%eax
f0100a23:	50                   	push   %eax
f0100a24:	e8 5f 01 00 00       	call   f0100b88 <cprintf>

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();

	// Remove this line when you're ready to test this function.
	panic("mem_init: This function is not finished\n");
f0100a29:	83 c4 0c             	add    $0xc,%esp
f0100a2c:	8d 83 d8 fc fe ff    	lea    -0x10328(%ebx),%eax
f0100a32:	50                   	push   %eax
f0100a33:	68 80 00 00 00       	push   $0x80
f0100a38:	8d 83 04 fd fe ff    	lea    -0x102fc(%ebx),%eax
f0100a3e:	50                   	push   %eax
f0100a3f:	e8 55 f6 ff ff       	call   f0100099 <_panic>

f0100a44 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100a44:	55                   	push   %ebp
f0100a45:	89 e5                	mov    %esp,%ebp
f0100a47:	57                   	push   %edi
f0100a48:	56                   	push   %esi
f0100a49:	53                   	push   %ebx
f0100a4a:	83 ec 04             	sub    $0x4,%esp
f0100a4d:	e8 ab 00 00 00       	call   f0100afd <__x86.get_pc_thunk.si>
f0100a52:	81 c6 b6 18 01 00    	add    $0x118b6,%esi
f0100a58:	89 75 f0             	mov    %esi,-0x10(%ebp)
f0100a5b:	8b 9e 90 1f 00 00    	mov    0x1f90(%esi),%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100a61:	ba 00 00 00 00       	mov    $0x0,%edx
f0100a66:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a6b:	c7 c7 a8 46 11 f0    	mov    $0xf01146a8,%edi
		pages[i].pp_ref = 0;
f0100a71:	c7 c6 b0 46 11 f0    	mov    $0xf01146b0,%esi
	for (i = 0; i < npages; i++) {
f0100a77:	eb 1f                	jmp    f0100a98 <page_init+0x54>
f0100a79:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100a80:	89 d1                	mov    %edx,%ecx
f0100a82:	03 0e                	add    (%esi),%ecx
f0100a84:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100a8a:	89 19                	mov    %ebx,(%ecx)
	for (i = 0; i < npages; i++) {
f0100a8c:	83 c0 01             	add    $0x1,%eax
		page_free_list = &pages[i];
f0100a8f:	89 d3                	mov    %edx,%ebx
f0100a91:	03 1e                	add    (%esi),%ebx
f0100a93:	ba 01 00 00 00       	mov    $0x1,%edx
	for (i = 0; i < npages; i++) {
f0100a98:	39 07                	cmp    %eax,(%edi)
f0100a9a:	77 dd                	ja     f0100a79 <page_init+0x35>
f0100a9c:	84 d2                	test   %dl,%dl
f0100a9e:	75 08                	jne    f0100aa8 <page_init+0x64>
	}
}
f0100aa0:	83 c4 04             	add    $0x4,%esp
f0100aa3:	5b                   	pop    %ebx
f0100aa4:	5e                   	pop    %esi
f0100aa5:	5f                   	pop    %edi
f0100aa6:	5d                   	pop    %ebp
f0100aa7:	c3                   	ret    
f0100aa8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100aab:	89 98 90 1f 00 00    	mov    %ebx,0x1f90(%eax)
f0100ab1:	eb ed                	jmp    f0100aa0 <page_init+0x5c>

f0100ab3 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100ab3:	55                   	push   %ebp
f0100ab4:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100ab6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100abb:	5d                   	pop    %ebp
f0100abc:	c3                   	ret    

f0100abd <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100abd:	55                   	push   %ebp
f0100abe:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f0100ac0:	5d                   	pop    %ebp
f0100ac1:	c3                   	ret    

f0100ac2 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100ac2:	55                   	push   %ebp
f0100ac3:	89 e5                	mov    %esp,%ebp
f0100ac5:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100ac8:	66 83 68 04 01       	subw   $0x1,0x4(%eax)
		page_free(pp);
}
f0100acd:	5d                   	pop    %ebp
f0100ace:	c3                   	ret    

f0100acf <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100acf:	55                   	push   %ebp
f0100ad0:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100ad2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ad7:	5d                   	pop    %ebp
f0100ad8:	c3                   	ret    

f0100ad9 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100ad9:	55                   	push   %ebp
f0100ada:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100adc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ae1:	5d                   	pop    %ebp
f0100ae2:	c3                   	ret    

f0100ae3 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100ae3:	55                   	push   %ebp
f0100ae4:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100ae6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100aeb:	5d                   	pop    %ebp
f0100aec:	c3                   	ret    

f0100aed <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100aed:	55                   	push   %ebp
f0100aee:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100af0:	5d                   	pop    %ebp
f0100af1:	c3                   	ret    

f0100af2 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100af2:	55                   	push   %ebp
f0100af3:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100af5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100af8:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100afb:	5d                   	pop    %ebp
f0100afc:	c3                   	ret    

f0100afd <__x86.get_pc_thunk.si>:
f0100afd:	8b 34 24             	mov    (%esp),%esi
f0100b00:	c3                   	ret    

f0100b01 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100b01:	55                   	push   %ebp
f0100b02:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100b04:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b07:	ba 70 00 00 00       	mov    $0x70,%edx
f0100b0c:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100b0d:	ba 71 00 00 00       	mov    $0x71,%edx
f0100b12:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100b13:	0f b6 c0             	movzbl %al,%eax
}
f0100b16:	5d                   	pop    %ebp
f0100b17:	c3                   	ret    

f0100b18 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100b18:	55                   	push   %ebp
f0100b19:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100b1b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b1e:	ba 70 00 00 00       	mov    $0x70,%edx
f0100b23:	ee                   	out    %al,(%dx)
f0100b24:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100b27:	ba 71 00 00 00       	mov    $0x71,%edx
f0100b2c:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100b2d:	5d                   	pop    %ebp
f0100b2e:	c3                   	ret    

f0100b2f <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100b2f:	55                   	push   %ebp
f0100b30:	89 e5                	mov    %esp,%ebp
f0100b32:	53                   	push   %ebx
f0100b33:	83 ec 10             	sub    $0x10,%esp
f0100b36:	e8 14 f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100b3b:	81 c3 cd 17 01 00    	add    $0x117cd,%ebx
	cputchar(ch);
f0100b41:	ff 75 08             	pushl  0x8(%ebp)
f0100b44:	e8 7d fb ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f0100b49:	83 c4 10             	add    $0x10,%esp
f0100b4c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b4f:	c9                   	leave  
f0100b50:	c3                   	ret    

f0100b51 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100b51:	55                   	push   %ebp
f0100b52:	89 e5                	mov    %esp,%ebp
f0100b54:	53                   	push   %ebx
f0100b55:	83 ec 14             	sub    $0x14,%esp
f0100b58:	e8 f2 f5 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100b5d:	81 c3 ab 17 01 00    	add    $0x117ab,%ebx
	int cnt = 0;
f0100b63:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100b6a:	ff 75 0c             	pushl  0xc(%ebp)
f0100b6d:	ff 75 08             	pushl  0x8(%ebp)
f0100b70:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100b73:	50                   	push   %eax
f0100b74:	8d 83 27 e8 fe ff    	lea    -0x117d9(%ebx),%eax
f0100b7a:	50                   	push   %eax
f0100b7b:	e8 1c 04 00 00       	call   f0100f9c <vprintfmt>
	return cnt;
}
f0100b80:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b83:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b86:	c9                   	leave  
f0100b87:	c3                   	ret    

f0100b88 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100b88:	55                   	push   %ebp
f0100b89:	89 e5                	mov    %esp,%ebp
f0100b8b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100b8e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100b91:	50                   	push   %eax
f0100b92:	ff 75 08             	pushl  0x8(%ebp)
f0100b95:	e8 b7 ff ff ff       	call   f0100b51 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100b9a:	c9                   	leave  
f0100b9b:	c3                   	ret    

f0100b9c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100b9c:	55                   	push   %ebp
f0100b9d:	89 e5                	mov    %esp,%ebp
f0100b9f:	57                   	push   %edi
f0100ba0:	56                   	push   %esi
f0100ba1:	53                   	push   %ebx
f0100ba2:	83 ec 14             	sub    $0x14,%esp
f0100ba5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100ba8:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100bab:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100bae:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100bb1:	8b 32                	mov    (%edx),%esi
f0100bb3:	8b 01                	mov    (%ecx),%eax
f0100bb5:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100bb8:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100bbf:	eb 2f                	jmp    f0100bf0 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100bc1:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100bc4:	39 c6                	cmp    %eax,%esi
f0100bc6:	7f 49                	jg     f0100c11 <stab_binsearch+0x75>
f0100bc8:	0f b6 0a             	movzbl (%edx),%ecx
f0100bcb:	83 ea 0c             	sub    $0xc,%edx
f0100bce:	39 f9                	cmp    %edi,%ecx
f0100bd0:	75 ef                	jne    f0100bc1 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100bd2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100bd5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100bd8:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100bdc:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100bdf:	73 35                	jae    f0100c16 <stab_binsearch+0x7a>
			*region_left = m;
f0100be1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100be4:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100be6:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100be9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100bf0:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100bf3:	7f 4e                	jg     f0100c43 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100bf5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100bf8:	01 f0                	add    %esi,%eax
f0100bfa:	89 c3                	mov    %eax,%ebx
f0100bfc:	c1 eb 1f             	shr    $0x1f,%ebx
f0100bff:	01 c3                	add    %eax,%ebx
f0100c01:	d1 fb                	sar    %ebx
f0100c03:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c06:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100c09:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100c0d:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100c0f:	eb b3                	jmp    f0100bc4 <stab_binsearch+0x28>
			l = true_m + 1;
f0100c11:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100c14:	eb da                	jmp    f0100bf0 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100c16:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100c19:	76 14                	jbe    f0100c2f <stab_binsearch+0x93>
			*region_right = m - 1;
f0100c1b:	83 e8 01             	sub    $0x1,%eax
f0100c1e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100c21:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100c24:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100c26:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100c2d:	eb c1                	jmp    f0100bf0 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100c2f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c32:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100c34:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100c38:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100c3a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100c41:	eb ad                	jmp    f0100bf0 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100c43:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100c47:	74 16                	je     f0100c5f <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100c49:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c4c:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100c4e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c51:	8b 0e                	mov    (%esi),%ecx
f0100c53:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100c56:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100c59:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100c5d:	eb 12                	jmp    f0100c71 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100c5f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c62:	8b 00                	mov    (%eax),%eax
f0100c64:	83 e8 01             	sub    $0x1,%eax
f0100c67:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100c6a:	89 07                	mov    %eax,(%edi)
f0100c6c:	eb 16                	jmp    f0100c84 <stab_binsearch+0xe8>
		     l--)
f0100c6e:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100c71:	39 c1                	cmp    %eax,%ecx
f0100c73:	7d 0a                	jge    f0100c7f <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100c75:	0f b6 1a             	movzbl (%edx),%ebx
f0100c78:	83 ea 0c             	sub    $0xc,%edx
f0100c7b:	39 fb                	cmp    %edi,%ebx
f0100c7d:	75 ef                	jne    f0100c6e <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100c7f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c82:	89 07                	mov    %eax,(%edi)
	}
}
f0100c84:	83 c4 14             	add    $0x14,%esp
f0100c87:	5b                   	pop    %ebx
f0100c88:	5e                   	pop    %esi
f0100c89:	5f                   	pop    %edi
f0100c8a:	5d                   	pop    %ebp
f0100c8b:	c3                   	ret    

f0100c8c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100c8c:	55                   	push   %ebp
f0100c8d:	89 e5                	mov    %esp,%ebp
f0100c8f:	57                   	push   %edi
f0100c90:	56                   	push   %esi
f0100c91:	53                   	push   %ebx
f0100c92:	83 ec 2c             	sub    $0x2c,%esp
f0100c95:	e8 fa 01 00 00       	call   f0100e94 <__x86.get_pc_thunk.cx>
f0100c9a:	81 c1 6e 16 01 00    	add    $0x1166e,%ecx
f0100ca0:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100ca3:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100ca6:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ca9:	8d 81 10 fd fe ff    	lea    -0x102f0(%ecx),%eax
f0100caf:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0100cb1:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0100cb8:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0100cbb:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0100cc2:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0100cc5:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ccc:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0100cd2:	0f 86 f4 00 00 00    	jbe    f0100dcc <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100cd8:	c7 c0 cd 65 10 f0    	mov    $0xf01065cd,%eax
f0100cde:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f0100ce4:	0f 86 88 01 00 00    	jbe    f0100e72 <debuginfo_eip+0x1e6>
f0100cea:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100ced:	c7 c0 e5 81 10 f0    	mov    $0xf01081e5,%eax
f0100cf3:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100cf7:	0f 85 7c 01 00 00    	jne    f0100e79 <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100cfd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100d04:	c7 c0 34 22 10 f0    	mov    $0xf0102234,%eax
f0100d0a:	c7 c2 cc 65 10 f0    	mov    $0xf01065cc,%edx
f0100d10:	29 c2                	sub    %eax,%edx
f0100d12:	c1 fa 02             	sar    $0x2,%edx
f0100d15:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100d1b:	83 ea 01             	sub    $0x1,%edx
f0100d1e:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100d21:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100d24:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100d27:	83 ec 08             	sub    $0x8,%esp
f0100d2a:	53                   	push   %ebx
f0100d2b:	6a 64                	push   $0x64
f0100d2d:	e8 6a fe ff ff       	call   f0100b9c <stab_binsearch>
	if (lfile == 0)
f0100d32:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d35:	83 c4 10             	add    $0x10,%esp
f0100d38:	85 c0                	test   %eax,%eax
f0100d3a:	0f 84 40 01 00 00    	je     f0100e80 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100d40:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100d43:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d46:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100d49:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100d4c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100d4f:	83 ec 08             	sub    $0x8,%esp
f0100d52:	53                   	push   %ebx
f0100d53:	6a 24                	push   $0x24
f0100d55:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100d58:	c7 c0 34 22 10 f0    	mov    $0xf0102234,%eax
f0100d5e:	e8 39 fe ff ff       	call   f0100b9c <stab_binsearch>

	if (lfun <= rfun) {
f0100d63:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100d66:	83 c4 10             	add    $0x10,%esp
f0100d69:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0100d6c:	7f 79                	jg     f0100de7 <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100d6e:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100d71:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d74:	c7 c2 34 22 10 f0    	mov    $0xf0102234,%edx
f0100d7a:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0100d7d:	8b 11                	mov    (%ecx),%edx
f0100d7f:	c7 c0 e5 81 10 f0    	mov    $0xf01081e5,%eax
f0100d85:	81 e8 cd 65 10 f0    	sub    $0xf01065cd,%eax
f0100d8b:	39 c2                	cmp    %eax,%edx
f0100d8d:	73 09                	jae    f0100d98 <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100d8f:	81 c2 cd 65 10 f0    	add    $0xf01065cd,%edx
f0100d95:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100d98:	8b 41 08             	mov    0x8(%ecx),%eax
f0100d9b:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100d9e:	83 ec 08             	sub    $0x8,%esp
f0100da1:	6a 3a                	push   $0x3a
f0100da3:	ff 77 08             	pushl  0x8(%edi)
f0100da6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100da9:	e8 1e 09 00 00       	call   f01016cc <strfind>
f0100dae:	2b 47 08             	sub    0x8(%edi),%eax
f0100db1:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100db4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100db7:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100dba:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100dbd:	c7 c2 34 22 10 f0    	mov    $0xf0102234,%edx
f0100dc3:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f0100dc7:	83 c4 10             	add    $0x10,%esp
f0100dca:	eb 29                	jmp    f0100df5 <debuginfo_eip+0x169>
  	        panic("User address");
f0100dcc:	83 ec 04             	sub    $0x4,%esp
f0100dcf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100dd2:	8d 83 1a fd fe ff    	lea    -0x102e6(%ebx),%eax
f0100dd8:	50                   	push   %eax
f0100dd9:	6a 7f                	push   $0x7f
f0100ddb:	8d 83 27 fd fe ff    	lea    -0x102d9(%ebx),%eax
f0100de1:	50                   	push   %eax
f0100de2:	e8 b2 f2 ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f0100de7:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0100dea:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ded:	eb af                	jmp    f0100d9e <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100def:	83 ee 01             	sub    $0x1,%esi
f0100df2:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100df5:	39 f3                	cmp    %esi,%ebx
f0100df7:	7f 3a                	jg     f0100e33 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f0100df9:	0f b6 10             	movzbl (%eax),%edx
f0100dfc:	80 fa 84             	cmp    $0x84,%dl
f0100dff:	74 0b                	je     f0100e0c <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100e01:	80 fa 64             	cmp    $0x64,%dl
f0100e04:	75 e9                	jne    f0100def <debuginfo_eip+0x163>
f0100e06:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100e0a:	74 e3                	je     f0100def <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100e0c:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0100e0f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100e12:	c7 c0 34 22 10 f0    	mov    $0xf0102234,%eax
f0100e18:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100e1b:	c7 c0 e5 81 10 f0    	mov    $0xf01081e5,%eax
f0100e21:	81 e8 cd 65 10 f0    	sub    $0xf01065cd,%eax
f0100e27:	39 c2                	cmp    %eax,%edx
f0100e29:	73 08                	jae    f0100e33 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100e2b:	81 c2 cd 65 10 f0    	add    $0xf01065cd,%edx
f0100e31:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100e33:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100e36:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100e39:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100e3e:	39 cb                	cmp    %ecx,%ebx
f0100e40:	7d 4a                	jge    f0100e8c <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0100e42:	8d 53 01             	lea    0x1(%ebx),%edx
f0100e45:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f0100e48:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e4b:	c7 c0 34 22 10 f0    	mov    $0xf0102234,%eax
f0100e51:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0100e55:	eb 07                	jmp    f0100e5e <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0100e57:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0100e5b:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0100e5e:	39 d1                	cmp    %edx,%ecx
f0100e60:	74 25                	je     f0100e87 <debuginfo_eip+0x1fb>
f0100e62:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100e65:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0100e69:	74 ec                	je     f0100e57 <debuginfo_eip+0x1cb>
	return 0;
f0100e6b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e70:	eb 1a                	jmp    f0100e8c <debuginfo_eip+0x200>
		return -1;
f0100e72:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e77:	eb 13                	jmp    f0100e8c <debuginfo_eip+0x200>
f0100e79:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e7e:	eb 0c                	jmp    f0100e8c <debuginfo_eip+0x200>
		return -1;
f0100e80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e85:	eb 05                	jmp    f0100e8c <debuginfo_eip+0x200>
	return 0;
f0100e87:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e8c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e8f:	5b                   	pop    %ebx
f0100e90:	5e                   	pop    %esi
f0100e91:	5f                   	pop    %edi
f0100e92:	5d                   	pop    %ebp
f0100e93:	c3                   	ret    

f0100e94 <__x86.get_pc_thunk.cx>:
f0100e94:	8b 0c 24             	mov    (%esp),%ecx
f0100e97:	c3                   	ret    

f0100e98 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100e98:	55                   	push   %ebp
f0100e99:	89 e5                	mov    %esp,%ebp
f0100e9b:	57                   	push   %edi
f0100e9c:	56                   	push   %esi
f0100e9d:	53                   	push   %ebx
f0100e9e:	83 ec 2c             	sub    $0x2c,%esp
f0100ea1:	e8 ee ff ff ff       	call   f0100e94 <__x86.get_pc_thunk.cx>
f0100ea6:	81 c1 62 14 01 00    	add    $0x11462,%ecx
f0100eac:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100eaf:	89 c7                	mov    %eax,%edi
f0100eb1:	89 d6                	mov    %edx,%esi
f0100eb3:	8b 45 08             	mov    0x8(%ebp),%eax
f0100eb6:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100eb9:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100ebc:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100ebf:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100ec2:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100ec7:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100eca:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100ecd:	39 d3                	cmp    %edx,%ebx
f0100ecf:	72 09                	jb     f0100eda <printnum+0x42>
f0100ed1:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100ed4:	0f 87 83 00 00 00    	ja     f0100f5d <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100eda:	83 ec 0c             	sub    $0xc,%esp
f0100edd:	ff 75 18             	pushl  0x18(%ebp)
f0100ee0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee3:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100ee6:	53                   	push   %ebx
f0100ee7:	ff 75 10             	pushl  0x10(%ebp)
f0100eea:	83 ec 08             	sub    $0x8,%esp
f0100eed:	ff 75 dc             	pushl  -0x24(%ebp)
f0100ef0:	ff 75 d8             	pushl  -0x28(%ebp)
f0100ef3:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100ef6:	ff 75 d0             	pushl  -0x30(%ebp)
f0100ef9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100efc:	e8 ef 09 00 00       	call   f01018f0 <__udivdi3>
f0100f01:	83 c4 18             	add    $0x18,%esp
f0100f04:	52                   	push   %edx
f0100f05:	50                   	push   %eax
f0100f06:	89 f2                	mov    %esi,%edx
f0100f08:	89 f8                	mov    %edi,%eax
f0100f0a:	e8 89 ff ff ff       	call   f0100e98 <printnum>
f0100f0f:	83 c4 20             	add    $0x20,%esp
f0100f12:	eb 13                	jmp    f0100f27 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100f14:	83 ec 08             	sub    $0x8,%esp
f0100f17:	56                   	push   %esi
f0100f18:	ff 75 18             	pushl  0x18(%ebp)
f0100f1b:	ff d7                	call   *%edi
f0100f1d:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100f20:	83 eb 01             	sub    $0x1,%ebx
f0100f23:	85 db                	test   %ebx,%ebx
f0100f25:	7f ed                	jg     f0100f14 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100f27:	83 ec 08             	sub    $0x8,%esp
f0100f2a:	56                   	push   %esi
f0100f2b:	83 ec 04             	sub    $0x4,%esp
f0100f2e:	ff 75 dc             	pushl  -0x24(%ebp)
f0100f31:	ff 75 d8             	pushl  -0x28(%ebp)
f0100f34:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100f37:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f3a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100f3d:	89 f3                	mov    %esi,%ebx
f0100f3f:	e8 cc 0a 00 00       	call   f0101a10 <__umoddi3>
f0100f44:	83 c4 14             	add    $0x14,%esp
f0100f47:	0f be 84 06 35 fd fe 	movsbl -0x102cb(%esi,%eax,1),%eax
f0100f4e:	ff 
f0100f4f:	50                   	push   %eax
f0100f50:	ff d7                	call   *%edi
}
f0100f52:	83 c4 10             	add    $0x10,%esp
f0100f55:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f58:	5b                   	pop    %ebx
f0100f59:	5e                   	pop    %esi
f0100f5a:	5f                   	pop    %edi
f0100f5b:	5d                   	pop    %ebp
f0100f5c:	c3                   	ret    
f0100f5d:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100f60:	eb be                	jmp    f0100f20 <printnum+0x88>

f0100f62 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100f62:	55                   	push   %ebp
f0100f63:	89 e5                	mov    %esp,%ebp
f0100f65:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100f68:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100f6c:	8b 10                	mov    (%eax),%edx
f0100f6e:	3b 50 04             	cmp    0x4(%eax),%edx
f0100f71:	73 0a                	jae    f0100f7d <sprintputch+0x1b>
		*b->buf++ = ch;
f0100f73:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100f76:	89 08                	mov    %ecx,(%eax)
f0100f78:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f7b:	88 02                	mov    %al,(%edx)
}
f0100f7d:	5d                   	pop    %ebp
f0100f7e:	c3                   	ret    

f0100f7f <printfmt>:
{
f0100f7f:	55                   	push   %ebp
f0100f80:	89 e5                	mov    %esp,%ebp
f0100f82:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100f85:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100f88:	50                   	push   %eax
f0100f89:	ff 75 10             	pushl  0x10(%ebp)
f0100f8c:	ff 75 0c             	pushl  0xc(%ebp)
f0100f8f:	ff 75 08             	pushl  0x8(%ebp)
f0100f92:	e8 05 00 00 00       	call   f0100f9c <vprintfmt>
}
f0100f97:	83 c4 10             	add    $0x10,%esp
f0100f9a:	c9                   	leave  
f0100f9b:	c3                   	ret    

f0100f9c <vprintfmt>:
{
f0100f9c:	55                   	push   %ebp
f0100f9d:	89 e5                	mov    %esp,%ebp
f0100f9f:	57                   	push   %edi
f0100fa0:	56                   	push   %esi
f0100fa1:	53                   	push   %ebx
f0100fa2:	83 ec 2c             	sub    $0x2c,%esp
f0100fa5:	e8 a5 f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100faa:	81 c3 5e 13 01 00    	add    $0x1135e,%ebx
f0100fb0:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100fb3:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100fb6:	e9 8e 03 00 00       	jmp    f0101349 <.L35+0x48>
		padc = ' ';
f0100fbb:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0100fbf:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0100fc6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f0100fcd:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0100fd4:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100fd9:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100fdc:	8d 47 01             	lea    0x1(%edi),%eax
f0100fdf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fe2:	0f b6 17             	movzbl (%edi),%edx
f0100fe5:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100fe8:	3c 55                	cmp    $0x55,%al
f0100fea:	0f 87 e1 03 00 00    	ja     f01013d1 <.L22>
f0100ff0:	0f b6 c0             	movzbl %al,%eax
f0100ff3:	89 d9                	mov    %ebx,%ecx
f0100ff5:	03 8c 83 c4 fd fe ff 	add    -0x1023c(%ebx,%eax,4),%ecx
f0100ffc:	ff e1                	jmp    *%ecx

f0100ffe <.L67>:
f0100ffe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0101001:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0101005:	eb d5                	jmp    f0100fdc <vprintfmt+0x40>

f0101007 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0101007:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f010100a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010100e:	eb cc                	jmp    f0100fdc <vprintfmt+0x40>

f0101010 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0101010:	0f b6 d2             	movzbl %dl,%edx
f0101013:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0101016:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f010101b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010101e:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0101022:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0101025:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0101028:	83 f9 09             	cmp    $0x9,%ecx
f010102b:	77 55                	ja     f0101082 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f010102d:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0101030:	eb e9                	jmp    f010101b <.L29+0xb>

f0101032 <.L26>:
			precision = va_arg(ap, int);
f0101032:	8b 45 14             	mov    0x14(%ebp),%eax
f0101035:	8b 00                	mov    (%eax),%eax
f0101037:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010103a:	8b 45 14             	mov    0x14(%ebp),%eax
f010103d:	8d 40 04             	lea    0x4(%eax),%eax
f0101040:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101043:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0101046:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010104a:	79 90                	jns    f0100fdc <vprintfmt+0x40>
				width = precision, precision = -1;
f010104c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010104f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101052:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101059:	eb 81                	jmp    f0100fdc <vprintfmt+0x40>

f010105b <.L27>:
f010105b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010105e:	85 c0                	test   %eax,%eax
f0101060:	ba 00 00 00 00       	mov    $0x0,%edx
f0101065:	0f 49 d0             	cmovns %eax,%edx
f0101068:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010106b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010106e:	e9 69 ff ff ff       	jmp    f0100fdc <vprintfmt+0x40>

f0101073 <.L23>:
f0101073:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0101076:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010107d:	e9 5a ff ff ff       	jmp    f0100fdc <vprintfmt+0x40>
f0101082:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101085:	eb bf                	jmp    f0101046 <.L26+0x14>

f0101087 <.L33>:
			lflag++;
f0101087:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010108b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010108e:	e9 49 ff ff ff       	jmp    f0100fdc <vprintfmt+0x40>

f0101093 <.L30>:
			putch(va_arg(ap, int), putdat);
f0101093:	8b 45 14             	mov    0x14(%ebp),%eax
f0101096:	8d 78 04             	lea    0x4(%eax),%edi
f0101099:	83 ec 08             	sub    $0x8,%esp
f010109c:	56                   	push   %esi
f010109d:	ff 30                	pushl  (%eax)
f010109f:	ff 55 08             	call   *0x8(%ebp)
			break;
f01010a2:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f01010a5:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f01010a8:	e9 99 02 00 00       	jmp    f0101346 <.L35+0x45>

f01010ad <.L32>:
			err = va_arg(ap, int);
f01010ad:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b0:	8d 78 04             	lea    0x4(%eax),%edi
f01010b3:	8b 00                	mov    (%eax),%eax
f01010b5:	99                   	cltd   
f01010b6:	31 d0                	xor    %edx,%eax
f01010b8:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01010ba:	83 f8 06             	cmp    $0x6,%eax
f01010bd:	7f 27                	jg     f01010e6 <.L32+0x39>
f01010bf:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f01010c6:	85 d2                	test   %edx,%edx
f01010c8:	74 1c                	je     f01010e6 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01010ca:	52                   	push   %edx
f01010cb:	8d 83 56 fd fe ff    	lea    -0x102aa(%ebx),%eax
f01010d1:	50                   	push   %eax
f01010d2:	56                   	push   %esi
f01010d3:	ff 75 08             	pushl  0x8(%ebp)
f01010d6:	e8 a4 fe ff ff       	call   f0100f7f <printfmt>
f01010db:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01010de:	89 7d 14             	mov    %edi,0x14(%ebp)
f01010e1:	e9 60 02 00 00       	jmp    f0101346 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f01010e6:	50                   	push   %eax
f01010e7:	8d 83 4d fd fe ff    	lea    -0x102b3(%ebx),%eax
f01010ed:	50                   	push   %eax
f01010ee:	56                   	push   %esi
f01010ef:	ff 75 08             	pushl  0x8(%ebp)
f01010f2:	e8 88 fe ff ff       	call   f0100f7f <printfmt>
f01010f7:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01010fa:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01010fd:	e9 44 02 00 00       	jmp    f0101346 <.L35+0x45>

f0101102 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0101102:	8b 45 14             	mov    0x14(%ebp),%eax
f0101105:	83 c0 04             	add    $0x4,%eax
f0101108:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010110b:	8b 45 14             	mov    0x14(%ebp),%eax
f010110e:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101110:	85 ff                	test   %edi,%edi
f0101112:	8d 83 46 fd fe ff    	lea    -0x102ba(%ebx),%eax
f0101118:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010111b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010111f:	0f 8e b5 00 00 00    	jle    f01011da <.L36+0xd8>
f0101125:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101129:	75 08                	jne    f0101133 <.L36+0x31>
f010112b:	89 75 0c             	mov    %esi,0xc(%ebp)
f010112e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101131:	eb 6d                	jmp    f01011a0 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101133:	83 ec 08             	sub    $0x8,%esp
f0101136:	ff 75 d0             	pushl  -0x30(%ebp)
f0101139:	57                   	push   %edi
f010113a:	e8 49 04 00 00       	call   f0101588 <strnlen>
f010113f:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101142:	29 c2                	sub    %eax,%edx
f0101144:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0101147:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010114a:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010114e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101151:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101154:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101156:	eb 10                	jmp    f0101168 <.L36+0x66>
					putch(padc, putdat);
f0101158:	83 ec 08             	sub    $0x8,%esp
f010115b:	56                   	push   %esi
f010115c:	ff 75 e0             	pushl  -0x20(%ebp)
f010115f:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101162:	83 ef 01             	sub    $0x1,%edi
f0101165:	83 c4 10             	add    $0x10,%esp
f0101168:	85 ff                	test   %edi,%edi
f010116a:	7f ec                	jg     f0101158 <.L36+0x56>
f010116c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010116f:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0101172:	85 d2                	test   %edx,%edx
f0101174:	b8 00 00 00 00       	mov    $0x0,%eax
f0101179:	0f 49 c2             	cmovns %edx,%eax
f010117c:	29 c2                	sub    %eax,%edx
f010117e:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101181:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101184:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101187:	eb 17                	jmp    f01011a0 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0101189:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010118d:	75 30                	jne    f01011bf <.L36+0xbd>
					putch(ch, putdat);
f010118f:	83 ec 08             	sub    $0x8,%esp
f0101192:	ff 75 0c             	pushl  0xc(%ebp)
f0101195:	50                   	push   %eax
f0101196:	ff 55 08             	call   *0x8(%ebp)
f0101199:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010119c:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f01011a0:	83 c7 01             	add    $0x1,%edi
f01011a3:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f01011a7:	0f be c2             	movsbl %dl,%eax
f01011aa:	85 c0                	test   %eax,%eax
f01011ac:	74 52                	je     f0101200 <.L36+0xfe>
f01011ae:	85 f6                	test   %esi,%esi
f01011b0:	78 d7                	js     f0101189 <.L36+0x87>
f01011b2:	83 ee 01             	sub    $0x1,%esi
f01011b5:	79 d2                	jns    f0101189 <.L36+0x87>
f01011b7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01011ba:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01011bd:	eb 32                	jmp    f01011f1 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01011bf:	0f be d2             	movsbl %dl,%edx
f01011c2:	83 ea 20             	sub    $0x20,%edx
f01011c5:	83 fa 5e             	cmp    $0x5e,%edx
f01011c8:	76 c5                	jbe    f010118f <.L36+0x8d>
					putch('?', putdat);
f01011ca:	83 ec 08             	sub    $0x8,%esp
f01011cd:	ff 75 0c             	pushl  0xc(%ebp)
f01011d0:	6a 3f                	push   $0x3f
f01011d2:	ff 55 08             	call   *0x8(%ebp)
f01011d5:	83 c4 10             	add    $0x10,%esp
f01011d8:	eb c2                	jmp    f010119c <.L36+0x9a>
f01011da:	89 75 0c             	mov    %esi,0xc(%ebp)
f01011dd:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01011e0:	eb be                	jmp    f01011a0 <.L36+0x9e>
				putch(' ', putdat);
f01011e2:	83 ec 08             	sub    $0x8,%esp
f01011e5:	56                   	push   %esi
f01011e6:	6a 20                	push   $0x20
f01011e8:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01011eb:	83 ef 01             	sub    $0x1,%edi
f01011ee:	83 c4 10             	add    $0x10,%esp
f01011f1:	85 ff                	test   %edi,%edi
f01011f3:	7f ed                	jg     f01011e2 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01011f5:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01011f8:	89 45 14             	mov    %eax,0x14(%ebp)
f01011fb:	e9 46 01 00 00       	jmp    f0101346 <.L35+0x45>
f0101200:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101203:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101206:	eb e9                	jmp    f01011f1 <.L36+0xef>

f0101208 <.L31>:
f0101208:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f010120b:	83 f9 01             	cmp    $0x1,%ecx
f010120e:	7e 40                	jle    f0101250 <.L31+0x48>
		return va_arg(*ap, long long);
f0101210:	8b 45 14             	mov    0x14(%ebp),%eax
f0101213:	8b 50 04             	mov    0x4(%eax),%edx
f0101216:	8b 00                	mov    (%eax),%eax
f0101218:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010121b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010121e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101221:	8d 40 08             	lea    0x8(%eax),%eax
f0101224:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101227:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010122b:	79 55                	jns    f0101282 <.L31+0x7a>
				putch('-', putdat);
f010122d:	83 ec 08             	sub    $0x8,%esp
f0101230:	56                   	push   %esi
f0101231:	6a 2d                	push   $0x2d
f0101233:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101236:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101239:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010123c:	f7 da                	neg    %edx
f010123e:	83 d1 00             	adc    $0x0,%ecx
f0101241:	f7 d9                	neg    %ecx
f0101243:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101246:	b8 0a 00 00 00       	mov    $0xa,%eax
f010124b:	e9 db 00 00 00       	jmp    f010132b <.L35+0x2a>
	else if (lflag)
f0101250:	85 c9                	test   %ecx,%ecx
f0101252:	75 17                	jne    f010126b <.L31+0x63>
		return va_arg(*ap, int);
f0101254:	8b 45 14             	mov    0x14(%ebp),%eax
f0101257:	8b 00                	mov    (%eax),%eax
f0101259:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010125c:	99                   	cltd   
f010125d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101260:	8b 45 14             	mov    0x14(%ebp),%eax
f0101263:	8d 40 04             	lea    0x4(%eax),%eax
f0101266:	89 45 14             	mov    %eax,0x14(%ebp)
f0101269:	eb bc                	jmp    f0101227 <.L31+0x1f>
		return va_arg(*ap, long);
f010126b:	8b 45 14             	mov    0x14(%ebp),%eax
f010126e:	8b 00                	mov    (%eax),%eax
f0101270:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101273:	99                   	cltd   
f0101274:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101277:	8b 45 14             	mov    0x14(%ebp),%eax
f010127a:	8d 40 04             	lea    0x4(%eax),%eax
f010127d:	89 45 14             	mov    %eax,0x14(%ebp)
f0101280:	eb a5                	jmp    f0101227 <.L31+0x1f>
			num = getint(&ap, lflag);
f0101282:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101285:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101288:	b8 0a 00 00 00       	mov    $0xa,%eax
f010128d:	e9 99 00 00 00       	jmp    f010132b <.L35+0x2a>

f0101292 <.L37>:
f0101292:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101295:	83 f9 01             	cmp    $0x1,%ecx
f0101298:	7e 15                	jle    f01012af <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f010129a:	8b 45 14             	mov    0x14(%ebp),%eax
f010129d:	8b 10                	mov    (%eax),%edx
f010129f:	8b 48 04             	mov    0x4(%eax),%ecx
f01012a2:	8d 40 08             	lea    0x8(%eax),%eax
f01012a5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012a8:	b8 0a 00 00 00       	mov    $0xa,%eax
f01012ad:	eb 7c                	jmp    f010132b <.L35+0x2a>
	else if (lflag)
f01012af:	85 c9                	test   %ecx,%ecx
f01012b1:	75 17                	jne    f01012ca <.L37+0x38>
		return va_arg(*ap, unsigned int);
f01012b3:	8b 45 14             	mov    0x14(%ebp),%eax
f01012b6:	8b 10                	mov    (%eax),%edx
f01012b8:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012bd:	8d 40 04             	lea    0x4(%eax),%eax
f01012c0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012c3:	b8 0a 00 00 00       	mov    $0xa,%eax
f01012c8:	eb 61                	jmp    f010132b <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01012ca:	8b 45 14             	mov    0x14(%ebp),%eax
f01012cd:	8b 10                	mov    (%eax),%edx
f01012cf:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012d4:	8d 40 04             	lea    0x4(%eax),%eax
f01012d7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012da:	b8 0a 00 00 00       	mov    $0xa,%eax
f01012df:	eb 4a                	jmp    f010132b <.L35+0x2a>

f01012e1 <.L34>:
			putch('X', putdat);
f01012e1:	83 ec 08             	sub    $0x8,%esp
f01012e4:	56                   	push   %esi
f01012e5:	6a 58                	push   $0x58
f01012e7:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01012ea:	83 c4 08             	add    $0x8,%esp
f01012ed:	56                   	push   %esi
f01012ee:	6a 58                	push   $0x58
f01012f0:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01012f3:	83 c4 08             	add    $0x8,%esp
f01012f6:	56                   	push   %esi
f01012f7:	6a 58                	push   $0x58
f01012f9:	ff 55 08             	call   *0x8(%ebp)
			break;
f01012fc:	83 c4 10             	add    $0x10,%esp
f01012ff:	eb 45                	jmp    f0101346 <.L35+0x45>

f0101301 <.L35>:
			putch('0', putdat);
f0101301:	83 ec 08             	sub    $0x8,%esp
f0101304:	56                   	push   %esi
f0101305:	6a 30                	push   $0x30
f0101307:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010130a:	83 c4 08             	add    $0x8,%esp
f010130d:	56                   	push   %esi
f010130e:	6a 78                	push   $0x78
f0101310:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0101313:	8b 45 14             	mov    0x14(%ebp),%eax
f0101316:	8b 10                	mov    (%eax),%edx
f0101318:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010131d:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101320:	8d 40 04             	lea    0x4(%eax),%eax
f0101323:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101326:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f010132b:	83 ec 0c             	sub    $0xc,%esp
f010132e:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101332:	57                   	push   %edi
f0101333:	ff 75 e0             	pushl  -0x20(%ebp)
f0101336:	50                   	push   %eax
f0101337:	51                   	push   %ecx
f0101338:	52                   	push   %edx
f0101339:	89 f2                	mov    %esi,%edx
f010133b:	8b 45 08             	mov    0x8(%ebp),%eax
f010133e:	e8 55 fb ff ff       	call   f0100e98 <printnum>
			break;
f0101343:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0101346:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101349:	83 c7 01             	add    $0x1,%edi
f010134c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101350:	83 f8 25             	cmp    $0x25,%eax
f0101353:	0f 84 62 fc ff ff    	je     f0100fbb <vprintfmt+0x1f>
			if (ch == '\0')
f0101359:	85 c0                	test   %eax,%eax
f010135b:	0f 84 91 00 00 00    	je     f01013f2 <.L22+0x21>
			putch(ch, putdat);
f0101361:	83 ec 08             	sub    $0x8,%esp
f0101364:	56                   	push   %esi
f0101365:	50                   	push   %eax
f0101366:	ff 55 08             	call   *0x8(%ebp)
f0101369:	83 c4 10             	add    $0x10,%esp
f010136c:	eb db                	jmp    f0101349 <.L35+0x48>

f010136e <.L38>:
f010136e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101371:	83 f9 01             	cmp    $0x1,%ecx
f0101374:	7e 15                	jle    f010138b <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0101376:	8b 45 14             	mov    0x14(%ebp),%eax
f0101379:	8b 10                	mov    (%eax),%edx
f010137b:	8b 48 04             	mov    0x4(%eax),%ecx
f010137e:	8d 40 08             	lea    0x8(%eax),%eax
f0101381:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101384:	b8 10 00 00 00       	mov    $0x10,%eax
f0101389:	eb a0                	jmp    f010132b <.L35+0x2a>
	else if (lflag)
f010138b:	85 c9                	test   %ecx,%ecx
f010138d:	75 17                	jne    f01013a6 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f010138f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101392:	8b 10                	mov    (%eax),%edx
f0101394:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101399:	8d 40 04             	lea    0x4(%eax),%eax
f010139c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010139f:	b8 10 00 00 00       	mov    $0x10,%eax
f01013a4:	eb 85                	jmp    f010132b <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01013a6:	8b 45 14             	mov    0x14(%ebp),%eax
f01013a9:	8b 10                	mov    (%eax),%edx
f01013ab:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013b0:	8d 40 04             	lea    0x4(%eax),%eax
f01013b3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01013b6:	b8 10 00 00 00       	mov    $0x10,%eax
f01013bb:	e9 6b ff ff ff       	jmp    f010132b <.L35+0x2a>

f01013c0 <.L25>:
			putch(ch, putdat);
f01013c0:	83 ec 08             	sub    $0x8,%esp
f01013c3:	56                   	push   %esi
f01013c4:	6a 25                	push   $0x25
f01013c6:	ff 55 08             	call   *0x8(%ebp)
			break;
f01013c9:	83 c4 10             	add    $0x10,%esp
f01013cc:	e9 75 ff ff ff       	jmp    f0101346 <.L35+0x45>

f01013d1 <.L22>:
			putch('%', putdat);
f01013d1:	83 ec 08             	sub    $0x8,%esp
f01013d4:	56                   	push   %esi
f01013d5:	6a 25                	push   $0x25
f01013d7:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01013da:	83 c4 10             	add    $0x10,%esp
f01013dd:	89 f8                	mov    %edi,%eax
f01013df:	eb 03                	jmp    f01013e4 <.L22+0x13>
f01013e1:	83 e8 01             	sub    $0x1,%eax
f01013e4:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01013e8:	75 f7                	jne    f01013e1 <.L22+0x10>
f01013ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01013ed:	e9 54 ff ff ff       	jmp    f0101346 <.L35+0x45>
}
f01013f2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013f5:	5b                   	pop    %ebx
f01013f6:	5e                   	pop    %esi
f01013f7:	5f                   	pop    %edi
f01013f8:	5d                   	pop    %ebp
f01013f9:	c3                   	ret    

f01013fa <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01013fa:	55                   	push   %ebp
f01013fb:	89 e5                	mov    %esp,%ebp
f01013fd:	53                   	push   %ebx
f01013fe:	83 ec 14             	sub    $0x14,%esp
f0101401:	e8 49 ed ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101406:	81 c3 02 0f 01 00    	add    $0x10f02,%ebx
f010140c:	8b 45 08             	mov    0x8(%ebp),%eax
f010140f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101412:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101415:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101419:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010141c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101423:	85 c0                	test   %eax,%eax
f0101425:	74 2b                	je     f0101452 <vsnprintf+0x58>
f0101427:	85 d2                	test   %edx,%edx
f0101429:	7e 27                	jle    f0101452 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010142b:	ff 75 14             	pushl  0x14(%ebp)
f010142e:	ff 75 10             	pushl  0x10(%ebp)
f0101431:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101434:	50                   	push   %eax
f0101435:	8d 83 5a ec fe ff    	lea    -0x113a6(%ebx),%eax
f010143b:	50                   	push   %eax
f010143c:	e8 5b fb ff ff       	call   f0100f9c <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101441:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101444:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101447:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010144a:	83 c4 10             	add    $0x10,%esp
}
f010144d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101450:	c9                   	leave  
f0101451:	c3                   	ret    
		return -E_INVAL;
f0101452:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101457:	eb f4                	jmp    f010144d <vsnprintf+0x53>

f0101459 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101459:	55                   	push   %ebp
f010145a:	89 e5                	mov    %esp,%ebp
f010145c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010145f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101462:	50                   	push   %eax
f0101463:	ff 75 10             	pushl  0x10(%ebp)
f0101466:	ff 75 0c             	pushl  0xc(%ebp)
f0101469:	ff 75 08             	pushl  0x8(%ebp)
f010146c:	e8 89 ff ff ff       	call   f01013fa <vsnprintf>
	va_end(ap);

	return rc;
}
f0101471:	c9                   	leave  
f0101472:	c3                   	ret    

f0101473 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101473:	55                   	push   %ebp
f0101474:	89 e5                	mov    %esp,%ebp
f0101476:	57                   	push   %edi
f0101477:	56                   	push   %esi
f0101478:	53                   	push   %ebx
f0101479:	83 ec 1c             	sub    $0x1c,%esp
f010147c:	e8 ce ec ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101481:	81 c3 87 0e 01 00    	add    $0x10e87,%ebx
f0101487:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010148a:	85 c0                	test   %eax,%eax
f010148c:	74 13                	je     f01014a1 <readline+0x2e>
		cprintf("%s", prompt);
f010148e:	83 ec 08             	sub    $0x8,%esp
f0101491:	50                   	push   %eax
f0101492:	8d 83 56 fd fe ff    	lea    -0x102aa(%ebx),%eax
f0101498:	50                   	push   %eax
f0101499:	e8 ea f6 ff ff       	call   f0100b88 <cprintf>
f010149e:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01014a1:	83 ec 0c             	sub    $0xc,%esp
f01014a4:	6a 00                	push   $0x0
f01014a6:	e8 3c f2 ff ff       	call   f01006e7 <iscons>
f01014ab:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01014ae:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01014b1:	bf 00 00 00 00       	mov    $0x0,%edi
f01014b6:	eb 46                	jmp    f01014fe <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01014b8:	83 ec 08             	sub    $0x8,%esp
f01014bb:	50                   	push   %eax
f01014bc:	8d 83 1c ff fe ff    	lea    -0x100e4(%ebx),%eax
f01014c2:	50                   	push   %eax
f01014c3:	e8 c0 f6 ff ff       	call   f0100b88 <cprintf>
			return NULL;
f01014c8:	83 c4 10             	add    $0x10,%esp
f01014cb:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01014d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014d3:	5b                   	pop    %ebx
f01014d4:	5e                   	pop    %esi
f01014d5:	5f                   	pop    %edi
f01014d6:	5d                   	pop    %ebp
f01014d7:	c3                   	ret    
			if (echoing)
f01014d8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01014dc:	75 05                	jne    f01014e3 <readline+0x70>
			i--;
f01014de:	83 ef 01             	sub    $0x1,%edi
f01014e1:	eb 1b                	jmp    f01014fe <readline+0x8b>
				cputchar('\b');
f01014e3:	83 ec 0c             	sub    $0xc,%esp
f01014e6:	6a 08                	push   $0x8
f01014e8:	e8 d9 f1 ff ff       	call   f01006c6 <cputchar>
f01014ed:	83 c4 10             	add    $0x10,%esp
f01014f0:	eb ec                	jmp    f01014de <readline+0x6b>
			buf[i++] = c;
f01014f2:	89 f0                	mov    %esi,%eax
f01014f4:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f01014fb:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f01014fe:	e8 d3 f1 ff ff       	call   f01006d6 <getchar>
f0101503:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0101505:	85 c0                	test   %eax,%eax
f0101507:	78 af                	js     f01014b8 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101509:	83 f8 08             	cmp    $0x8,%eax
f010150c:	0f 94 c2             	sete   %dl
f010150f:	83 f8 7f             	cmp    $0x7f,%eax
f0101512:	0f 94 c0             	sete   %al
f0101515:	08 c2                	or     %al,%dl
f0101517:	74 04                	je     f010151d <readline+0xaa>
f0101519:	85 ff                	test   %edi,%edi
f010151b:	7f bb                	jg     f01014d8 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010151d:	83 fe 1f             	cmp    $0x1f,%esi
f0101520:	7e 1c                	jle    f010153e <readline+0xcb>
f0101522:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0101528:	7f 14                	jg     f010153e <readline+0xcb>
			if (echoing)
f010152a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010152e:	74 c2                	je     f01014f2 <readline+0x7f>
				cputchar(c);
f0101530:	83 ec 0c             	sub    $0xc,%esp
f0101533:	56                   	push   %esi
f0101534:	e8 8d f1 ff ff       	call   f01006c6 <cputchar>
f0101539:	83 c4 10             	add    $0x10,%esp
f010153c:	eb b4                	jmp    f01014f2 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f010153e:	83 fe 0a             	cmp    $0xa,%esi
f0101541:	74 05                	je     f0101548 <readline+0xd5>
f0101543:	83 fe 0d             	cmp    $0xd,%esi
f0101546:	75 b6                	jne    f01014fe <readline+0x8b>
			if (echoing)
f0101548:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010154c:	75 13                	jne    f0101561 <readline+0xee>
			buf[i] = 0;
f010154e:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f0101555:	00 
			return buf;
f0101556:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f010155c:	e9 6f ff ff ff       	jmp    f01014d0 <readline+0x5d>
				cputchar('\n');
f0101561:	83 ec 0c             	sub    $0xc,%esp
f0101564:	6a 0a                	push   $0xa
f0101566:	e8 5b f1 ff ff       	call   f01006c6 <cputchar>
f010156b:	83 c4 10             	add    $0x10,%esp
f010156e:	eb de                	jmp    f010154e <readline+0xdb>

f0101570 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101570:	55                   	push   %ebp
f0101571:	89 e5                	mov    %esp,%ebp
f0101573:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101576:	b8 00 00 00 00       	mov    $0x0,%eax
f010157b:	eb 03                	jmp    f0101580 <strlen+0x10>
		n++;
f010157d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0101580:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101584:	75 f7                	jne    f010157d <strlen+0xd>
	return n;
}
f0101586:	5d                   	pop    %ebp
f0101587:	c3                   	ret    

f0101588 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101588:	55                   	push   %ebp
f0101589:	89 e5                	mov    %esp,%ebp
f010158b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010158e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101591:	b8 00 00 00 00       	mov    $0x0,%eax
f0101596:	eb 03                	jmp    f010159b <strnlen+0x13>
		n++;
f0101598:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010159b:	39 d0                	cmp    %edx,%eax
f010159d:	74 06                	je     f01015a5 <strnlen+0x1d>
f010159f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01015a3:	75 f3                	jne    f0101598 <strnlen+0x10>
	return n;
}
f01015a5:	5d                   	pop    %ebp
f01015a6:	c3                   	ret    

f01015a7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01015a7:	55                   	push   %ebp
f01015a8:	89 e5                	mov    %esp,%ebp
f01015aa:	53                   	push   %ebx
f01015ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01015ae:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01015b1:	89 c2                	mov    %eax,%edx
f01015b3:	83 c1 01             	add    $0x1,%ecx
f01015b6:	83 c2 01             	add    $0x1,%edx
f01015b9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01015bd:	88 5a ff             	mov    %bl,-0x1(%edx)
f01015c0:	84 db                	test   %bl,%bl
f01015c2:	75 ef                	jne    f01015b3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01015c4:	5b                   	pop    %ebx
f01015c5:	5d                   	pop    %ebp
f01015c6:	c3                   	ret    

f01015c7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01015c7:	55                   	push   %ebp
f01015c8:	89 e5                	mov    %esp,%ebp
f01015ca:	53                   	push   %ebx
f01015cb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01015ce:	53                   	push   %ebx
f01015cf:	e8 9c ff ff ff       	call   f0101570 <strlen>
f01015d4:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01015d7:	ff 75 0c             	pushl  0xc(%ebp)
f01015da:	01 d8                	add    %ebx,%eax
f01015dc:	50                   	push   %eax
f01015dd:	e8 c5 ff ff ff       	call   f01015a7 <strcpy>
	return dst;
}
f01015e2:	89 d8                	mov    %ebx,%eax
f01015e4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01015e7:	c9                   	leave  
f01015e8:	c3                   	ret    

f01015e9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01015e9:	55                   	push   %ebp
f01015ea:	89 e5                	mov    %esp,%ebp
f01015ec:	56                   	push   %esi
f01015ed:	53                   	push   %ebx
f01015ee:	8b 75 08             	mov    0x8(%ebp),%esi
f01015f1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01015f4:	89 f3                	mov    %esi,%ebx
f01015f6:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01015f9:	89 f2                	mov    %esi,%edx
f01015fb:	eb 0f                	jmp    f010160c <strncpy+0x23>
		*dst++ = *src;
f01015fd:	83 c2 01             	add    $0x1,%edx
f0101600:	0f b6 01             	movzbl (%ecx),%eax
f0101603:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101606:	80 39 01             	cmpb   $0x1,(%ecx)
f0101609:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f010160c:	39 da                	cmp    %ebx,%edx
f010160e:	75 ed                	jne    f01015fd <strncpy+0x14>
	}
	return ret;
}
f0101610:	89 f0                	mov    %esi,%eax
f0101612:	5b                   	pop    %ebx
f0101613:	5e                   	pop    %esi
f0101614:	5d                   	pop    %ebp
f0101615:	c3                   	ret    

f0101616 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101616:	55                   	push   %ebp
f0101617:	89 e5                	mov    %esp,%ebp
f0101619:	56                   	push   %esi
f010161a:	53                   	push   %ebx
f010161b:	8b 75 08             	mov    0x8(%ebp),%esi
f010161e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101621:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101624:	89 f0                	mov    %esi,%eax
f0101626:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010162a:	85 c9                	test   %ecx,%ecx
f010162c:	75 0b                	jne    f0101639 <strlcpy+0x23>
f010162e:	eb 17                	jmp    f0101647 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101630:	83 c2 01             	add    $0x1,%edx
f0101633:	83 c0 01             	add    $0x1,%eax
f0101636:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101639:	39 d8                	cmp    %ebx,%eax
f010163b:	74 07                	je     f0101644 <strlcpy+0x2e>
f010163d:	0f b6 0a             	movzbl (%edx),%ecx
f0101640:	84 c9                	test   %cl,%cl
f0101642:	75 ec                	jne    f0101630 <strlcpy+0x1a>
		*dst = '\0';
f0101644:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101647:	29 f0                	sub    %esi,%eax
}
f0101649:	5b                   	pop    %ebx
f010164a:	5e                   	pop    %esi
f010164b:	5d                   	pop    %ebp
f010164c:	c3                   	ret    

f010164d <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010164d:	55                   	push   %ebp
f010164e:	89 e5                	mov    %esp,%ebp
f0101650:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101653:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101656:	eb 06                	jmp    f010165e <strcmp+0x11>
		p++, q++;
f0101658:	83 c1 01             	add    $0x1,%ecx
f010165b:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f010165e:	0f b6 01             	movzbl (%ecx),%eax
f0101661:	84 c0                	test   %al,%al
f0101663:	74 04                	je     f0101669 <strcmp+0x1c>
f0101665:	3a 02                	cmp    (%edx),%al
f0101667:	74 ef                	je     f0101658 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101669:	0f b6 c0             	movzbl %al,%eax
f010166c:	0f b6 12             	movzbl (%edx),%edx
f010166f:	29 d0                	sub    %edx,%eax
}
f0101671:	5d                   	pop    %ebp
f0101672:	c3                   	ret    

f0101673 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101673:	55                   	push   %ebp
f0101674:	89 e5                	mov    %esp,%ebp
f0101676:	53                   	push   %ebx
f0101677:	8b 45 08             	mov    0x8(%ebp),%eax
f010167a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010167d:	89 c3                	mov    %eax,%ebx
f010167f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101682:	eb 06                	jmp    f010168a <strncmp+0x17>
		n--, p++, q++;
f0101684:	83 c0 01             	add    $0x1,%eax
f0101687:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f010168a:	39 d8                	cmp    %ebx,%eax
f010168c:	74 16                	je     f01016a4 <strncmp+0x31>
f010168e:	0f b6 08             	movzbl (%eax),%ecx
f0101691:	84 c9                	test   %cl,%cl
f0101693:	74 04                	je     f0101699 <strncmp+0x26>
f0101695:	3a 0a                	cmp    (%edx),%cl
f0101697:	74 eb                	je     f0101684 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101699:	0f b6 00             	movzbl (%eax),%eax
f010169c:	0f b6 12             	movzbl (%edx),%edx
f010169f:	29 d0                	sub    %edx,%eax
}
f01016a1:	5b                   	pop    %ebx
f01016a2:	5d                   	pop    %ebp
f01016a3:	c3                   	ret    
		return 0;
f01016a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01016a9:	eb f6                	jmp    f01016a1 <strncmp+0x2e>

f01016ab <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01016ab:	55                   	push   %ebp
f01016ac:	89 e5                	mov    %esp,%ebp
f01016ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01016b1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01016b5:	0f b6 10             	movzbl (%eax),%edx
f01016b8:	84 d2                	test   %dl,%dl
f01016ba:	74 09                	je     f01016c5 <strchr+0x1a>
		if (*s == c)
f01016bc:	38 ca                	cmp    %cl,%dl
f01016be:	74 0a                	je     f01016ca <strchr+0x1f>
	for (; *s; s++)
f01016c0:	83 c0 01             	add    $0x1,%eax
f01016c3:	eb f0                	jmp    f01016b5 <strchr+0xa>
			return (char *) s;
	return 0;
f01016c5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016ca:	5d                   	pop    %ebp
f01016cb:	c3                   	ret    

f01016cc <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01016cc:	55                   	push   %ebp
f01016cd:	89 e5                	mov    %esp,%ebp
f01016cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01016d2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01016d6:	eb 03                	jmp    f01016db <strfind+0xf>
f01016d8:	83 c0 01             	add    $0x1,%eax
f01016db:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01016de:	38 ca                	cmp    %cl,%dl
f01016e0:	74 04                	je     f01016e6 <strfind+0x1a>
f01016e2:	84 d2                	test   %dl,%dl
f01016e4:	75 f2                	jne    f01016d8 <strfind+0xc>
			break;
	return (char *) s;
}
f01016e6:	5d                   	pop    %ebp
f01016e7:	c3                   	ret    

f01016e8 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01016e8:	55                   	push   %ebp
f01016e9:	89 e5                	mov    %esp,%ebp
f01016eb:	57                   	push   %edi
f01016ec:	56                   	push   %esi
f01016ed:	53                   	push   %ebx
f01016ee:	8b 7d 08             	mov    0x8(%ebp),%edi
f01016f1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01016f4:	85 c9                	test   %ecx,%ecx
f01016f6:	74 13                	je     f010170b <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01016f8:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016fe:	75 05                	jne    f0101705 <memset+0x1d>
f0101700:	f6 c1 03             	test   $0x3,%cl
f0101703:	74 0d                	je     f0101712 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101705:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101708:	fc                   	cld    
f0101709:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010170b:	89 f8                	mov    %edi,%eax
f010170d:	5b                   	pop    %ebx
f010170e:	5e                   	pop    %esi
f010170f:	5f                   	pop    %edi
f0101710:	5d                   	pop    %ebp
f0101711:	c3                   	ret    
		c &= 0xFF;
f0101712:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101716:	89 d3                	mov    %edx,%ebx
f0101718:	c1 e3 08             	shl    $0x8,%ebx
f010171b:	89 d0                	mov    %edx,%eax
f010171d:	c1 e0 18             	shl    $0x18,%eax
f0101720:	89 d6                	mov    %edx,%esi
f0101722:	c1 e6 10             	shl    $0x10,%esi
f0101725:	09 f0                	or     %esi,%eax
f0101727:	09 c2                	or     %eax,%edx
f0101729:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f010172b:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f010172e:	89 d0                	mov    %edx,%eax
f0101730:	fc                   	cld    
f0101731:	f3 ab                	rep stos %eax,%es:(%edi)
f0101733:	eb d6                	jmp    f010170b <memset+0x23>

f0101735 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101735:	55                   	push   %ebp
f0101736:	89 e5                	mov    %esp,%ebp
f0101738:	57                   	push   %edi
f0101739:	56                   	push   %esi
f010173a:	8b 45 08             	mov    0x8(%ebp),%eax
f010173d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101740:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101743:	39 c6                	cmp    %eax,%esi
f0101745:	73 35                	jae    f010177c <memmove+0x47>
f0101747:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010174a:	39 c2                	cmp    %eax,%edx
f010174c:	76 2e                	jbe    f010177c <memmove+0x47>
		s += n;
		d += n;
f010174e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101751:	89 d6                	mov    %edx,%esi
f0101753:	09 fe                	or     %edi,%esi
f0101755:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010175b:	74 0c                	je     f0101769 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010175d:	83 ef 01             	sub    $0x1,%edi
f0101760:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101763:	fd                   	std    
f0101764:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101766:	fc                   	cld    
f0101767:	eb 21                	jmp    f010178a <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101769:	f6 c1 03             	test   $0x3,%cl
f010176c:	75 ef                	jne    f010175d <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010176e:	83 ef 04             	sub    $0x4,%edi
f0101771:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101774:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101777:	fd                   	std    
f0101778:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010177a:	eb ea                	jmp    f0101766 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010177c:	89 f2                	mov    %esi,%edx
f010177e:	09 c2                	or     %eax,%edx
f0101780:	f6 c2 03             	test   $0x3,%dl
f0101783:	74 09                	je     f010178e <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101785:	89 c7                	mov    %eax,%edi
f0101787:	fc                   	cld    
f0101788:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010178a:	5e                   	pop    %esi
f010178b:	5f                   	pop    %edi
f010178c:	5d                   	pop    %ebp
f010178d:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010178e:	f6 c1 03             	test   $0x3,%cl
f0101791:	75 f2                	jne    f0101785 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101793:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101796:	89 c7                	mov    %eax,%edi
f0101798:	fc                   	cld    
f0101799:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010179b:	eb ed                	jmp    f010178a <memmove+0x55>

f010179d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010179d:	55                   	push   %ebp
f010179e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01017a0:	ff 75 10             	pushl  0x10(%ebp)
f01017a3:	ff 75 0c             	pushl  0xc(%ebp)
f01017a6:	ff 75 08             	pushl  0x8(%ebp)
f01017a9:	e8 87 ff ff ff       	call   f0101735 <memmove>
}
f01017ae:	c9                   	leave  
f01017af:	c3                   	ret    

f01017b0 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01017b0:	55                   	push   %ebp
f01017b1:	89 e5                	mov    %esp,%ebp
f01017b3:	56                   	push   %esi
f01017b4:	53                   	push   %ebx
f01017b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01017b8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01017bb:	89 c6                	mov    %eax,%esi
f01017bd:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01017c0:	39 f0                	cmp    %esi,%eax
f01017c2:	74 1c                	je     f01017e0 <memcmp+0x30>
		if (*s1 != *s2)
f01017c4:	0f b6 08             	movzbl (%eax),%ecx
f01017c7:	0f b6 1a             	movzbl (%edx),%ebx
f01017ca:	38 d9                	cmp    %bl,%cl
f01017cc:	75 08                	jne    f01017d6 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01017ce:	83 c0 01             	add    $0x1,%eax
f01017d1:	83 c2 01             	add    $0x1,%edx
f01017d4:	eb ea                	jmp    f01017c0 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01017d6:	0f b6 c1             	movzbl %cl,%eax
f01017d9:	0f b6 db             	movzbl %bl,%ebx
f01017dc:	29 d8                	sub    %ebx,%eax
f01017de:	eb 05                	jmp    f01017e5 <memcmp+0x35>
	}

	return 0;
f01017e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01017e5:	5b                   	pop    %ebx
f01017e6:	5e                   	pop    %esi
f01017e7:	5d                   	pop    %ebp
f01017e8:	c3                   	ret    

f01017e9 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01017e9:	55                   	push   %ebp
f01017ea:	89 e5                	mov    %esp,%ebp
f01017ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01017ef:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01017f2:	89 c2                	mov    %eax,%edx
f01017f4:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01017f7:	39 d0                	cmp    %edx,%eax
f01017f9:	73 09                	jae    f0101804 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017fb:	38 08                	cmp    %cl,(%eax)
f01017fd:	74 05                	je     f0101804 <memfind+0x1b>
	for (; s < ends; s++)
f01017ff:	83 c0 01             	add    $0x1,%eax
f0101802:	eb f3                	jmp    f01017f7 <memfind+0xe>
			break;
	return (void *) s;
}
f0101804:	5d                   	pop    %ebp
f0101805:	c3                   	ret    

f0101806 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101806:	55                   	push   %ebp
f0101807:	89 e5                	mov    %esp,%ebp
f0101809:	57                   	push   %edi
f010180a:	56                   	push   %esi
f010180b:	53                   	push   %ebx
f010180c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010180f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101812:	eb 03                	jmp    f0101817 <strtol+0x11>
		s++;
f0101814:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0101817:	0f b6 01             	movzbl (%ecx),%eax
f010181a:	3c 20                	cmp    $0x20,%al
f010181c:	74 f6                	je     f0101814 <strtol+0xe>
f010181e:	3c 09                	cmp    $0x9,%al
f0101820:	74 f2                	je     f0101814 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101822:	3c 2b                	cmp    $0x2b,%al
f0101824:	74 2e                	je     f0101854 <strtol+0x4e>
	int neg = 0;
f0101826:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f010182b:	3c 2d                	cmp    $0x2d,%al
f010182d:	74 2f                	je     f010185e <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010182f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101835:	75 05                	jne    f010183c <strtol+0x36>
f0101837:	80 39 30             	cmpb   $0x30,(%ecx)
f010183a:	74 2c                	je     f0101868 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010183c:	85 db                	test   %ebx,%ebx
f010183e:	75 0a                	jne    f010184a <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101840:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0101845:	80 39 30             	cmpb   $0x30,(%ecx)
f0101848:	74 28                	je     f0101872 <strtol+0x6c>
		base = 10;
f010184a:	b8 00 00 00 00       	mov    $0x0,%eax
f010184f:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101852:	eb 50                	jmp    f01018a4 <strtol+0x9e>
		s++;
f0101854:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0101857:	bf 00 00 00 00       	mov    $0x0,%edi
f010185c:	eb d1                	jmp    f010182f <strtol+0x29>
		s++, neg = 1;
f010185e:	83 c1 01             	add    $0x1,%ecx
f0101861:	bf 01 00 00 00       	mov    $0x1,%edi
f0101866:	eb c7                	jmp    f010182f <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101868:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010186c:	74 0e                	je     f010187c <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010186e:	85 db                	test   %ebx,%ebx
f0101870:	75 d8                	jne    f010184a <strtol+0x44>
		s++, base = 8;
f0101872:	83 c1 01             	add    $0x1,%ecx
f0101875:	bb 08 00 00 00       	mov    $0x8,%ebx
f010187a:	eb ce                	jmp    f010184a <strtol+0x44>
		s += 2, base = 16;
f010187c:	83 c1 02             	add    $0x2,%ecx
f010187f:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101884:	eb c4                	jmp    f010184a <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0101886:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101889:	89 f3                	mov    %esi,%ebx
f010188b:	80 fb 19             	cmp    $0x19,%bl
f010188e:	77 29                	ja     f01018b9 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0101890:	0f be d2             	movsbl %dl,%edx
f0101893:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101896:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101899:	7d 30                	jge    f01018cb <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f010189b:	83 c1 01             	add    $0x1,%ecx
f010189e:	0f af 45 10          	imul   0x10(%ebp),%eax
f01018a2:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f01018a4:	0f b6 11             	movzbl (%ecx),%edx
f01018a7:	8d 72 d0             	lea    -0x30(%edx),%esi
f01018aa:	89 f3                	mov    %esi,%ebx
f01018ac:	80 fb 09             	cmp    $0x9,%bl
f01018af:	77 d5                	ja     f0101886 <strtol+0x80>
			dig = *s - '0';
f01018b1:	0f be d2             	movsbl %dl,%edx
f01018b4:	83 ea 30             	sub    $0x30,%edx
f01018b7:	eb dd                	jmp    f0101896 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f01018b9:	8d 72 bf             	lea    -0x41(%edx),%esi
f01018bc:	89 f3                	mov    %esi,%ebx
f01018be:	80 fb 19             	cmp    $0x19,%bl
f01018c1:	77 08                	ja     f01018cb <strtol+0xc5>
			dig = *s - 'A' + 10;
f01018c3:	0f be d2             	movsbl %dl,%edx
f01018c6:	83 ea 37             	sub    $0x37,%edx
f01018c9:	eb cb                	jmp    f0101896 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01018cb:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01018cf:	74 05                	je     f01018d6 <strtol+0xd0>
		*endptr = (char *) s;
f01018d1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018d4:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01018d6:	89 c2                	mov    %eax,%edx
f01018d8:	f7 da                	neg    %edx
f01018da:	85 ff                	test   %edi,%edi
f01018dc:	0f 45 c2             	cmovne %edx,%eax
}
f01018df:	5b                   	pop    %ebx
f01018e0:	5e                   	pop    %esi
f01018e1:	5f                   	pop    %edi
f01018e2:	5d                   	pop    %ebp
f01018e3:	c3                   	ret    
f01018e4:	66 90                	xchg   %ax,%ax
f01018e6:	66 90                	xchg   %ax,%ax
f01018e8:	66 90                	xchg   %ax,%ax
f01018ea:	66 90                	xchg   %ax,%ax
f01018ec:	66 90                	xchg   %ax,%ax
f01018ee:	66 90                	xchg   %ax,%ax

f01018f0 <__udivdi3>:
f01018f0:	55                   	push   %ebp
f01018f1:	57                   	push   %edi
f01018f2:	56                   	push   %esi
f01018f3:	53                   	push   %ebx
f01018f4:	83 ec 1c             	sub    $0x1c,%esp
f01018f7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01018fb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01018ff:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101903:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0101907:	85 d2                	test   %edx,%edx
f0101909:	75 35                	jne    f0101940 <__udivdi3+0x50>
f010190b:	39 f3                	cmp    %esi,%ebx
f010190d:	0f 87 bd 00 00 00    	ja     f01019d0 <__udivdi3+0xe0>
f0101913:	85 db                	test   %ebx,%ebx
f0101915:	89 d9                	mov    %ebx,%ecx
f0101917:	75 0b                	jne    f0101924 <__udivdi3+0x34>
f0101919:	b8 01 00 00 00       	mov    $0x1,%eax
f010191e:	31 d2                	xor    %edx,%edx
f0101920:	f7 f3                	div    %ebx
f0101922:	89 c1                	mov    %eax,%ecx
f0101924:	31 d2                	xor    %edx,%edx
f0101926:	89 f0                	mov    %esi,%eax
f0101928:	f7 f1                	div    %ecx
f010192a:	89 c6                	mov    %eax,%esi
f010192c:	89 e8                	mov    %ebp,%eax
f010192e:	89 f7                	mov    %esi,%edi
f0101930:	f7 f1                	div    %ecx
f0101932:	89 fa                	mov    %edi,%edx
f0101934:	83 c4 1c             	add    $0x1c,%esp
f0101937:	5b                   	pop    %ebx
f0101938:	5e                   	pop    %esi
f0101939:	5f                   	pop    %edi
f010193a:	5d                   	pop    %ebp
f010193b:	c3                   	ret    
f010193c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101940:	39 f2                	cmp    %esi,%edx
f0101942:	77 7c                	ja     f01019c0 <__udivdi3+0xd0>
f0101944:	0f bd fa             	bsr    %edx,%edi
f0101947:	83 f7 1f             	xor    $0x1f,%edi
f010194a:	0f 84 98 00 00 00    	je     f01019e8 <__udivdi3+0xf8>
f0101950:	89 f9                	mov    %edi,%ecx
f0101952:	b8 20 00 00 00       	mov    $0x20,%eax
f0101957:	29 f8                	sub    %edi,%eax
f0101959:	d3 e2                	shl    %cl,%edx
f010195b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010195f:	89 c1                	mov    %eax,%ecx
f0101961:	89 da                	mov    %ebx,%edx
f0101963:	d3 ea                	shr    %cl,%edx
f0101965:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101969:	09 d1                	or     %edx,%ecx
f010196b:	89 f2                	mov    %esi,%edx
f010196d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101971:	89 f9                	mov    %edi,%ecx
f0101973:	d3 e3                	shl    %cl,%ebx
f0101975:	89 c1                	mov    %eax,%ecx
f0101977:	d3 ea                	shr    %cl,%edx
f0101979:	89 f9                	mov    %edi,%ecx
f010197b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010197f:	d3 e6                	shl    %cl,%esi
f0101981:	89 eb                	mov    %ebp,%ebx
f0101983:	89 c1                	mov    %eax,%ecx
f0101985:	d3 eb                	shr    %cl,%ebx
f0101987:	09 de                	or     %ebx,%esi
f0101989:	89 f0                	mov    %esi,%eax
f010198b:	f7 74 24 08          	divl   0x8(%esp)
f010198f:	89 d6                	mov    %edx,%esi
f0101991:	89 c3                	mov    %eax,%ebx
f0101993:	f7 64 24 0c          	mull   0xc(%esp)
f0101997:	39 d6                	cmp    %edx,%esi
f0101999:	72 0c                	jb     f01019a7 <__udivdi3+0xb7>
f010199b:	89 f9                	mov    %edi,%ecx
f010199d:	d3 e5                	shl    %cl,%ebp
f010199f:	39 c5                	cmp    %eax,%ebp
f01019a1:	73 5d                	jae    f0101a00 <__udivdi3+0x110>
f01019a3:	39 d6                	cmp    %edx,%esi
f01019a5:	75 59                	jne    f0101a00 <__udivdi3+0x110>
f01019a7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01019aa:	31 ff                	xor    %edi,%edi
f01019ac:	89 fa                	mov    %edi,%edx
f01019ae:	83 c4 1c             	add    $0x1c,%esp
f01019b1:	5b                   	pop    %ebx
f01019b2:	5e                   	pop    %esi
f01019b3:	5f                   	pop    %edi
f01019b4:	5d                   	pop    %ebp
f01019b5:	c3                   	ret    
f01019b6:	8d 76 00             	lea    0x0(%esi),%esi
f01019b9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01019c0:	31 ff                	xor    %edi,%edi
f01019c2:	31 c0                	xor    %eax,%eax
f01019c4:	89 fa                	mov    %edi,%edx
f01019c6:	83 c4 1c             	add    $0x1c,%esp
f01019c9:	5b                   	pop    %ebx
f01019ca:	5e                   	pop    %esi
f01019cb:	5f                   	pop    %edi
f01019cc:	5d                   	pop    %ebp
f01019cd:	c3                   	ret    
f01019ce:	66 90                	xchg   %ax,%ax
f01019d0:	31 ff                	xor    %edi,%edi
f01019d2:	89 e8                	mov    %ebp,%eax
f01019d4:	89 f2                	mov    %esi,%edx
f01019d6:	f7 f3                	div    %ebx
f01019d8:	89 fa                	mov    %edi,%edx
f01019da:	83 c4 1c             	add    $0x1c,%esp
f01019dd:	5b                   	pop    %ebx
f01019de:	5e                   	pop    %esi
f01019df:	5f                   	pop    %edi
f01019e0:	5d                   	pop    %ebp
f01019e1:	c3                   	ret    
f01019e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01019e8:	39 f2                	cmp    %esi,%edx
f01019ea:	72 06                	jb     f01019f2 <__udivdi3+0x102>
f01019ec:	31 c0                	xor    %eax,%eax
f01019ee:	39 eb                	cmp    %ebp,%ebx
f01019f0:	77 d2                	ja     f01019c4 <__udivdi3+0xd4>
f01019f2:	b8 01 00 00 00       	mov    $0x1,%eax
f01019f7:	eb cb                	jmp    f01019c4 <__udivdi3+0xd4>
f01019f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a00:	89 d8                	mov    %ebx,%eax
f0101a02:	31 ff                	xor    %edi,%edi
f0101a04:	eb be                	jmp    f01019c4 <__udivdi3+0xd4>
f0101a06:	66 90                	xchg   %ax,%ax
f0101a08:	66 90                	xchg   %ax,%ax
f0101a0a:	66 90                	xchg   %ax,%ax
f0101a0c:	66 90                	xchg   %ax,%ax
f0101a0e:	66 90                	xchg   %ax,%ax

f0101a10 <__umoddi3>:
f0101a10:	55                   	push   %ebp
f0101a11:	57                   	push   %edi
f0101a12:	56                   	push   %esi
f0101a13:	53                   	push   %ebx
f0101a14:	83 ec 1c             	sub    $0x1c,%esp
f0101a17:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0101a1b:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101a1f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101a23:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101a27:	85 ed                	test   %ebp,%ebp
f0101a29:	89 f0                	mov    %esi,%eax
f0101a2b:	89 da                	mov    %ebx,%edx
f0101a2d:	75 19                	jne    f0101a48 <__umoddi3+0x38>
f0101a2f:	39 df                	cmp    %ebx,%edi
f0101a31:	0f 86 b1 00 00 00    	jbe    f0101ae8 <__umoddi3+0xd8>
f0101a37:	f7 f7                	div    %edi
f0101a39:	89 d0                	mov    %edx,%eax
f0101a3b:	31 d2                	xor    %edx,%edx
f0101a3d:	83 c4 1c             	add    $0x1c,%esp
f0101a40:	5b                   	pop    %ebx
f0101a41:	5e                   	pop    %esi
f0101a42:	5f                   	pop    %edi
f0101a43:	5d                   	pop    %ebp
f0101a44:	c3                   	ret    
f0101a45:	8d 76 00             	lea    0x0(%esi),%esi
f0101a48:	39 dd                	cmp    %ebx,%ebp
f0101a4a:	77 f1                	ja     f0101a3d <__umoddi3+0x2d>
f0101a4c:	0f bd cd             	bsr    %ebp,%ecx
f0101a4f:	83 f1 1f             	xor    $0x1f,%ecx
f0101a52:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101a56:	0f 84 b4 00 00 00    	je     f0101b10 <__umoddi3+0x100>
f0101a5c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101a61:	89 c2                	mov    %eax,%edx
f0101a63:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101a67:	29 c2                	sub    %eax,%edx
f0101a69:	89 c1                	mov    %eax,%ecx
f0101a6b:	89 f8                	mov    %edi,%eax
f0101a6d:	d3 e5                	shl    %cl,%ebp
f0101a6f:	89 d1                	mov    %edx,%ecx
f0101a71:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101a75:	d3 e8                	shr    %cl,%eax
f0101a77:	09 c5                	or     %eax,%ebp
f0101a79:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101a7d:	89 c1                	mov    %eax,%ecx
f0101a7f:	d3 e7                	shl    %cl,%edi
f0101a81:	89 d1                	mov    %edx,%ecx
f0101a83:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101a87:	89 df                	mov    %ebx,%edi
f0101a89:	d3 ef                	shr    %cl,%edi
f0101a8b:	89 c1                	mov    %eax,%ecx
f0101a8d:	89 f0                	mov    %esi,%eax
f0101a8f:	d3 e3                	shl    %cl,%ebx
f0101a91:	89 d1                	mov    %edx,%ecx
f0101a93:	89 fa                	mov    %edi,%edx
f0101a95:	d3 e8                	shr    %cl,%eax
f0101a97:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a9c:	09 d8                	or     %ebx,%eax
f0101a9e:	f7 f5                	div    %ebp
f0101aa0:	d3 e6                	shl    %cl,%esi
f0101aa2:	89 d1                	mov    %edx,%ecx
f0101aa4:	f7 64 24 08          	mull   0x8(%esp)
f0101aa8:	39 d1                	cmp    %edx,%ecx
f0101aaa:	89 c3                	mov    %eax,%ebx
f0101aac:	89 d7                	mov    %edx,%edi
f0101aae:	72 06                	jb     f0101ab6 <__umoddi3+0xa6>
f0101ab0:	75 0e                	jne    f0101ac0 <__umoddi3+0xb0>
f0101ab2:	39 c6                	cmp    %eax,%esi
f0101ab4:	73 0a                	jae    f0101ac0 <__umoddi3+0xb0>
f0101ab6:	2b 44 24 08          	sub    0x8(%esp),%eax
f0101aba:	19 ea                	sbb    %ebp,%edx
f0101abc:	89 d7                	mov    %edx,%edi
f0101abe:	89 c3                	mov    %eax,%ebx
f0101ac0:	89 ca                	mov    %ecx,%edx
f0101ac2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101ac7:	29 de                	sub    %ebx,%esi
f0101ac9:	19 fa                	sbb    %edi,%edx
f0101acb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0101acf:	89 d0                	mov    %edx,%eax
f0101ad1:	d3 e0                	shl    %cl,%eax
f0101ad3:	89 d9                	mov    %ebx,%ecx
f0101ad5:	d3 ee                	shr    %cl,%esi
f0101ad7:	d3 ea                	shr    %cl,%edx
f0101ad9:	09 f0                	or     %esi,%eax
f0101adb:	83 c4 1c             	add    $0x1c,%esp
f0101ade:	5b                   	pop    %ebx
f0101adf:	5e                   	pop    %esi
f0101ae0:	5f                   	pop    %edi
f0101ae1:	5d                   	pop    %ebp
f0101ae2:	c3                   	ret    
f0101ae3:	90                   	nop
f0101ae4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ae8:	85 ff                	test   %edi,%edi
f0101aea:	89 f9                	mov    %edi,%ecx
f0101aec:	75 0b                	jne    f0101af9 <__umoddi3+0xe9>
f0101aee:	b8 01 00 00 00       	mov    $0x1,%eax
f0101af3:	31 d2                	xor    %edx,%edx
f0101af5:	f7 f7                	div    %edi
f0101af7:	89 c1                	mov    %eax,%ecx
f0101af9:	89 d8                	mov    %ebx,%eax
f0101afb:	31 d2                	xor    %edx,%edx
f0101afd:	f7 f1                	div    %ecx
f0101aff:	89 f0                	mov    %esi,%eax
f0101b01:	f7 f1                	div    %ecx
f0101b03:	e9 31 ff ff ff       	jmp    f0101a39 <__umoddi3+0x29>
f0101b08:	90                   	nop
f0101b09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b10:	39 dd                	cmp    %ebx,%ebp
f0101b12:	72 08                	jb     f0101b1c <__umoddi3+0x10c>
f0101b14:	39 f7                	cmp    %esi,%edi
f0101b16:	0f 87 21 ff ff ff    	ja     f0101a3d <__umoddi3+0x2d>
f0101b1c:	89 da                	mov    %ebx,%edx
f0101b1e:	89 f0                	mov    %esi,%eax
f0101b20:	29 f8                	sub    %edi,%eax
f0101b22:	19 ea                	sbb    %ebp,%edx
f0101b24:	e9 14 ff ff ff       	jmp    f0101a3d <__umoddi3+0x2d>
