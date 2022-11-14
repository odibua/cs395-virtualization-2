
obj/user/vmm:     file format elf64-x86-64


Disassembly of section .text:

0000000000800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	movabs $USTACKTOP, %rax
  800020:	48 b8 00 e0 7f ef 00 	movabs $0xef7fe000,%rax
  800027:	00 00 00 
	cmpq %rax,%rsp
  80002a:	48 39 c4             	cmp    %rax,%rsp
	jne args_exist
  80002d:	75 04                	jne    800033 <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushq $0
  80002f:	6a 00                	pushq  $0x0
	pushq $0
  800031:	6a 00                	pushq  $0x0

0000000000800033 <args_exist>:

args_exist:
	movq 8(%rsp), %rsi
  800033:	48 8b 74 24 08       	mov    0x8(%rsp),%rsi
	movq (%rsp), %rdi
  800038:	48 8b 3c 24          	mov    (%rsp),%rdi
	call libmain
  80003c:	e8 9c 06 00 00       	callq  8006dd <libmain>
1:	jmp 1b
  800041:	eb fe                	jmp    800041 <args_exist+0xe>

0000000000800043 <map_in_guest>:
// Return 0 on success, <0 on failure.
//
// Hint: Call sys_ept_map() for mapping page. 
static int
map_in_guest( envid_t guest, uintptr_t gpa, size_t memsz, 
	      int fd, size_t filesz, off_t fileoffset ) {
  800043:	55                   	push   %rbp
  800044:	48 89 e5             	mov    %rsp,%rbp
  800047:	48 83 ec 50          	sub    $0x50,%rsp
  80004b:	89 7d dc             	mov    %edi,-0x24(%rbp)
  80004e:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  800052:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  800056:	89 4d d8             	mov    %ecx,-0x28(%rbp)
  800059:	4c 89 45 c0          	mov    %r8,-0x40(%rbp)
  80005d:	44 89 4d bc          	mov    %r9d,-0x44(%rbp)
	int i, ret;

	i = PGOFF(gpa);
  800061:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800065:	25 ff 0f 00 00       	and    $0xfff,%eax
  80006a:	89 45 fc             	mov    %eax,-0x4(%rbp)
	// if the provided guest physical address is not page-aligned, 
	// adjust our values so we are working with a page-aligned address
	if (i) {
  80006d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  800071:	74 21                	je     800094 <map_in_guest+0x51>
		gpa -= i;
  800073:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800076:	48 98                	cltq   
  800078:	48 29 45 d0          	sub    %rax,-0x30(%rbp)
		memsz += i;
  80007c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80007f:	48 98                	cltq   
  800081:	48 01 45 c8          	add    %rax,-0x38(%rbp)
		filesz += i;
  800085:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800088:	48 98                	cltq   
  80008a:	48 01 45 c0          	add    %rax,-0x40(%rbp)
		fileoffset -= i;
  80008e:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800091:	29 45 bc             	sub    %eax,-0x44(%rbp)
	}

	// walk through the provided region page by page and copy in the file contents
	// the the physical memory region of the guest
	for (i = 0; i < memsz; i += PGSIZE) {
  800094:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  80009b:	e9 61 01 00 00       	jmpq   800201 <map_in_guest+0x1be>
		// allocate a temporary page
		ret = sys_page_alloc(0, UTEMP, PTE_P | PTE_U | PTE_W);
  8000a0:	ba 07 00 00 00       	mov    $0x7,%edx
  8000a5:	be 00 00 40 00       	mov    $0x400000,%esi
  8000aa:	bf 00 00 00 00       	mov    $0x0,%edi
  8000af:	48 b8 8c 1d 80 00 00 	movabs $0x801d8c,%rax
  8000b6:	00 00 00 
  8000b9:	ff d0                	callq  *%rax
  8000bb:	89 45 f8             	mov    %eax,-0x8(%rbp)
		if (ret < 0) {
  8000be:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8000c2:	79 1e                	jns    8000e2 <map_in_guest+0x9f>
			sys_page_unmap(0, UTEMP);
  8000c4:	be 00 00 40 00       	mov    $0x400000,%esi
  8000c9:	bf 00 00 00 00       	mov    $0x0,%edi
  8000ce:	48 b8 37 1e 80 00 00 	movabs $0x801e37,%rax
  8000d5:	00 00 00 
  8000d8:	ff d0                	callq  *%rax
			return ret;
  8000da:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8000dd:	e9 33 01 00 00       	jmpq   800215 <map_in_guest+0x1d2>
		}
		// seek to the location to write the file contents at
		ret = seek(fd, fileoffset + i);
  8000e2:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8000e5:	8b 55 bc             	mov    -0x44(%rbp),%edx
  8000e8:	01 c2                	add    %eax,%edx
  8000ea:	8b 45 d8             	mov    -0x28(%rbp),%eax
  8000ed:	89 d6                	mov    %edx,%esi
  8000ef:	89 c7                	mov    %eax,%edi
  8000f1:	48 b8 a0 29 80 00 00 	movabs $0x8029a0,%rax
  8000f8:	00 00 00 
  8000fb:	ff d0                	callq  *%rax
  8000fd:	89 45 f8             	mov    %eax,-0x8(%rbp)
		if (ret < 0) {
  800100:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  800104:	79 1e                	jns    800124 <map_in_guest+0xe1>
			sys_page_unmap(0, UTEMP);
  800106:	be 00 00 40 00       	mov    $0x400000,%esi
  80010b:	bf 00 00 00 00       	mov    $0x0,%edi
  800110:	48 b8 37 1e 80 00 00 	movabs $0x801e37,%rax
  800117:	00 00 00 
  80011a:	ff d0                	callq  *%rax
			return ret;
  80011c:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80011f:	e9 f1 00 00 00       	jmpq   800215 <map_in_guest+0x1d2>
		}
		// read file contents into the mapped page
		ret = readn(fd, UTEMP, MIN(PGSIZE, filesz-i));
  800124:	c7 45 f4 00 10 00 00 	movl   $0x1000,-0xc(%rbp)
  80012b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80012e:	48 98                	cltq   
  800130:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800134:	48 29 c2             	sub    %rax,%rdx
  800137:	48 89 d0             	mov    %rdx,%rax
  80013a:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  80013e:	8b 45 f4             	mov    -0xc(%rbp),%eax
  800141:	48 63 d0             	movslq %eax,%rdx
  800144:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800148:	48 39 c2             	cmp    %rax,%rdx
  80014b:	48 0f 47 d0          	cmova  %rax,%rdx
  80014f:	8b 45 d8             	mov    -0x28(%rbp),%eax
  800152:	be 00 00 40 00       	mov    $0x400000,%esi
  800157:	89 c7                	mov    %eax,%edi
  800159:	48 b8 57 28 80 00 00 	movabs $0x802857,%rax
  800160:	00 00 00 
  800163:	ff d0                	callq  *%rax
  800165:	89 45 f8             	mov    %eax,-0x8(%rbp)
		if (ret < 0) {
  800168:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  80016c:	79 1e                	jns    80018c <map_in_guest+0x149>
			sys_page_unmap(0, UTEMP);
  80016e:	be 00 00 40 00       	mov    $0x400000,%esi
  800173:	bf 00 00 00 00       	mov    $0x0,%edi
  800178:	48 b8 37 1e 80 00 00 	movabs $0x801e37,%rax
  80017f:	00 00 00 
  800182:	ff d0                	callq  *%rax
			return ret;
  800184:	8b 45 f8             	mov    -0x8(%rbp),%eax
  800187:	e9 89 00 00 00       	jmpq   800215 <map_in_guest+0x1d2>
		}
		// map the page in the EPT
		ret = sys_ept_map(0, UTEMP, guest, (void*) (gpa + i), __EPTE_FULL);
  80018c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80018f:	48 63 d0             	movslq %eax,%rdx
  800192:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800196:	48 01 d0             	add    %rdx,%rax
  800199:	48 89 c2             	mov    %rax,%rdx
  80019c:	8b 45 dc             	mov    -0x24(%rbp),%eax
  80019f:	41 b8 07 00 00 00    	mov    $0x7,%r8d
  8001a5:	48 89 d1             	mov    %rdx,%rcx
  8001a8:	89 c2                	mov    %eax,%edx
  8001aa:	be 00 00 40 00       	mov    $0x400000,%esi
  8001af:	bf 00 00 00 00       	mov    $0x0,%edi
  8001b4:	48 b8 c7 20 80 00 00 	movabs $0x8020c7,%rax
  8001bb:	00 00 00 
  8001be:	ff d0                	callq  *%rax
  8001c0:	89 45 f8             	mov    %eax,-0x8(%rbp)
		if (ret < 0) {
  8001c3:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8001c7:	79 1b                	jns    8001e4 <map_in_guest+0x1a1>
			sys_page_unmap(0, UTEMP);
  8001c9:	be 00 00 40 00       	mov    $0x400000,%esi
  8001ce:	bf 00 00 00 00       	mov    $0x0,%edi
  8001d3:	48 b8 37 1e 80 00 00 	movabs $0x801e37,%rax
  8001da:	00 00 00 
  8001dd:	ff d0                	callq  *%rax
			return ret;
  8001df:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8001e2:	eb 31                	jmp    800215 <map_in_guest+0x1d2>
		}
		sys_page_unmap(0, UTEMP);
  8001e4:	be 00 00 40 00       	mov    $0x400000,%esi
  8001e9:	bf 00 00 00 00       	mov    $0x0,%edi
  8001ee:	48 b8 37 1e 80 00 00 	movabs $0x801e37,%rax
  8001f5:	00 00 00 
  8001f8:	ff d0                	callq  *%rax
		fileoffset -= i;
	}

	// walk through the provided region page by page and copy in the file contents
	// the the physical memory region of the guest
	for (i = 0; i < memsz; i += PGSIZE) {
  8001fa:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%rbp)
  800201:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800204:	48 98                	cltq   
  800206:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  80020a:	0f 82 90 fe ff ff    	jb     8000a0 <map_in_guest+0x5d>
			return ret;
		}
		sys_page_unmap(0, UTEMP);
	}

	return 0;
  800210:	b8 00 00 00 00       	mov    $0x0,%eax
} 
  800215:	c9                   	leaveq 
  800216:	c3                   	retq   

0000000000800217 <copy_guest_kern_gpa>:
//
// Return 0 on success, <0 on error
//
// Hint: compare with ELF parsing in env.c, and use map_in_guest for each segment.
static int
copy_guest_kern_gpa( envid_t guest, char* fname ) {
  800217:	55                   	push   %rbp
  800218:	48 89 e5             	mov    %rsp,%rbp
  80021b:	41 57                	push   %r15
  80021d:	41 56                	push   %r14
  80021f:	41 55                	push   %r13
  800221:	41 54                	push   %r12
  800223:	53                   	push   %rbx
  800224:	48 83 ec 58          	sub    $0x58,%rsp
  800228:	89 7d 8c             	mov    %edi,-0x74(%rbp)
  80022b:	48 89 75 80          	mov    %rsi,-0x80(%rbp)
  80022f:	48 89 e0             	mov    %rsp,%rax
  800232:	48 89 c3             	mov    %rax,%rbx
	// open the specified file
	int fd, i, ret;
	fd = open(fname, O_RDONLY);
  800235:	48 8b 45 80          	mov    -0x80(%rbp),%rax
  800239:	be 00 00 00 00       	mov    $0x0,%esi
  80023e:	48 89 c7             	mov    %rax,%rdi
  800241:	48 b8 58 2c 80 00 00 	movabs $0x802c58,%rax
  800248:	00 00 00 
  80024b:	ff d0                	callq  *%rax
  80024d:	89 45 bc             	mov    %eax,-0x44(%rbp)
	if (fd < 0) {
  800250:	83 7d bc 00          	cmpl   $0x0,-0x44(%rbp)
  800254:	79 2d                	jns    800283 <copy_guest_kern_gpa+0x6c>
		cprintf("error opening %s: %e\n", fname, fd);
  800256:	8b 55 bc             	mov    -0x44(%rbp),%edx
  800259:	48 8b 45 80          	mov    -0x80(%rbp),%rax
  80025d:	48 89 c6             	mov    %rax,%rsi
  800260:	48 bf 20 47 80 00 00 	movabs $0x804720,%rdi
  800267:	00 00 00 
  80026a:	b8 00 00 00 00       	mov    $0x0,%eax
  80026f:	48 b9 a8 08 80 00 00 	movabs $0x8008a8,%rcx
  800276:	00 00 00 
  800279:	ff d1                	callq  *%rcx
		return fd;
  80027b:	8b 45 bc             	mov    -0x44(%rbp),%eax
  80027e:	e9 d5 01 00 00       	jmpq   800458 <copy_guest_kern_gpa+0x241>
	}

	int buflen = 512; // large enough to fit the whole Elf struct
  800283:	c7 45 b8 00 02 00 00 	movl   $0x200,-0x48(%rbp)
	unsigned char elf_buf[buflen];
  80028a:	8b 45 b8             	mov    -0x48(%rbp),%eax
  80028d:	48 63 d0             	movslq %eax,%rdx
  800290:	48 83 ea 01          	sub    $0x1,%rdx
  800294:	48 89 55 b0          	mov    %rdx,-0x50(%rbp)
  800298:	48 63 d0             	movslq %eax,%rdx
  80029b:	49 89 d6             	mov    %rdx,%r14
  80029e:	41 bf 00 00 00 00    	mov    $0x0,%r15d
  8002a4:	48 63 d0             	movslq %eax,%rdx
  8002a7:	49 89 d4             	mov    %rdx,%r12
  8002aa:	41 bd 00 00 00 00    	mov    $0x0,%r13d
  8002b0:	48 98                	cltq   
  8002b2:	ba 10 00 00 00       	mov    $0x10,%edx
  8002b7:	48 83 ea 01          	sub    $0x1,%rdx
  8002bb:	48 01 d0             	add    %rdx,%rax
  8002be:	b9 10 00 00 00       	mov    $0x10,%ecx
  8002c3:	ba 00 00 00 00       	mov    $0x0,%edx
  8002c8:	48 f7 f1             	div    %rcx
  8002cb:	48 6b c0 10          	imul   $0x10,%rax,%rax
  8002cf:	48 29 c4             	sub    %rax,%rsp
  8002d2:	48 89 e0             	mov    %rsp,%rax
  8002d5:	48 83 c0 00          	add    $0x0,%rax
  8002d9:	48 89 45 a8          	mov    %rax,-0x58(%rbp)
	struct Elf *elf;
	struct Proghdr *ph;

	// read in the header of file fname
	ret = readn(fd, elf_buf, buflen);
  8002dd:	8b 45 b8             	mov    -0x48(%rbp),%eax
  8002e0:	48 63 d0             	movslq %eax,%rdx
  8002e3:	48 8b 4d a8          	mov    -0x58(%rbp),%rcx
  8002e7:	8b 45 bc             	mov    -0x44(%rbp),%eax
  8002ea:	48 89 ce             	mov    %rcx,%rsi
  8002ed:	89 c7                	mov    %eax,%edi
  8002ef:	48 b8 57 28 80 00 00 	movabs $0x802857,%rax
  8002f6:	00 00 00 
  8002f9:	ff d0                	callq  *%rax
  8002fb:	89 45 a4             	mov    %eax,-0x5c(%rbp)
	if (ret != buflen) {
  8002fe:	8b 45 a4             	mov    -0x5c(%rbp),%eax
  800301:	3b 45 b8             	cmp    -0x48(%rbp),%eax
  800304:	74 36                	je     80033c <copy_guest_kern_gpa+0x125>
		close(fd);
  800306:	8b 45 bc             	mov    -0x44(%rbp),%eax
  800309:	89 c7                	mov    %eax,%edi
  80030b:	48 b8 60 25 80 00 00 	movabs $0x802560,%rax
  800312:	00 00 00 
  800315:	ff d0                	callq  *%rax
		cprintf("Failed to read in ELF header\n");
  800317:	48 bf 36 47 80 00 00 	movabs $0x804736,%rdi
  80031e:	00 00 00 
  800321:	b8 00 00 00 00       	mov    $0x0,%eax
  800326:	48 ba a8 08 80 00 00 	movabs $0x8008a8,%rdx
  80032d:	00 00 00 
  800330:	ff d2                	callq  *%rdx
		return -E_NOT_EXEC;
  800332:	b8 f1 ff ff ff       	mov    $0xfffffff1,%eax
  800337:	e9 1c 01 00 00       	jmpq   800458 <copy_guest_kern_gpa+0x241>
	}

	// point the elf struct at the elf buf
	elf = (struct Elf*) elf_buf;
  80033c:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800340:	48 89 45 98          	mov    %rax,-0x68(%rbp)

	// check the ELF header's magic value to check that we are working with a valid ELF binary
	if (elf->e_magic != ELF_MAGIC) {
  800344:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800348:	8b 00                	mov    (%rax),%eax
  80034a:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
  80034f:	74 39                	je     80038a <copy_guest_kern_gpa+0x173>
		close(fd);
  800351:	8b 45 bc             	mov    -0x44(%rbp),%eax
  800354:	89 c7                	mov    %eax,%edi
  800356:	48 b8 60 25 80 00 00 	movabs $0x802560,%rax
  80035d:	00 00 00 
  800360:	ff d0                	callq  *%rax
		cprintf("ELF magic is %08x, expected %08x\n", elf->e_magic, ELF_MAGIC);
  800362:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800366:	8b 00                	mov    (%rax),%eax
  800368:	ba 7f 45 4c 46       	mov    $0x464c457f,%edx
  80036d:	89 c6                	mov    %eax,%esi
  80036f:	48 bf 58 47 80 00 00 	movabs $0x804758,%rdi
  800376:	00 00 00 
  800379:	b8 00 00 00 00       	mov    $0x0,%eax
  80037e:	48 b9 a8 08 80 00 00 	movabs $0x8008a8,%rcx
  800385:	00 00 00 
  800388:	ff d1                	callq  *%rcx
	}

	// point the program header struct at the location indicated by the elf header
	ph = (struct Proghdr* ) (elf_buf + elf->e_phoff);
  80038a:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  80038e:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800392:	48 8b 40 20          	mov    0x20(%rax),%rax
  800396:	48 01 d0             	add    %rdx,%rax
  800399:	48 89 45 c0          	mov    %rax,-0x40(%rbp)

	// for every entry in the program header table, map the corresponding entry of the file 
	// into the guest's physical address space
	for (i = 0; i < elf->e_phnum; i++, ph++) {
  80039d:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%rbp)
  8003a4:	e9 85 00 00 00       	jmpq   80042e <copy_guest_kern_gpa+0x217>
		ret = map_in_guest(guest, ph->p_pa, ph->p_memsz, fd, ph->p_filesz, ph->p_offset);
  8003a9:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8003ad:	48 8b 40 08          	mov    0x8(%rax),%rax
  8003b1:	41 89 c0             	mov    %eax,%r8d
  8003b4:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8003b8:	48 8b 78 20          	mov    0x20(%rax),%rdi
  8003bc:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8003c0:	48 8b 50 28          	mov    0x28(%rax),%rdx
  8003c4:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8003c8:	48 8b 70 18          	mov    0x18(%rax),%rsi
  8003cc:	8b 4d bc             	mov    -0x44(%rbp),%ecx
  8003cf:	8b 45 8c             	mov    -0x74(%rbp),%eax
  8003d2:	45 89 c1             	mov    %r8d,%r9d
  8003d5:	49 89 f8             	mov    %rdi,%r8
  8003d8:	89 c7                	mov    %eax,%edi
  8003da:	48 b8 43 00 80 00 00 	movabs $0x800043,%rax
  8003e1:	00 00 00 
  8003e4:	ff d0                	callq  *%rax
  8003e6:	89 45 a4             	mov    %eax,-0x5c(%rbp)
		if (ret < 0) {
  8003e9:	83 7d a4 00          	cmpl   $0x0,-0x5c(%rbp)
  8003ed:	79 36                	jns    800425 <copy_guest_kern_gpa+0x20e>
			cprintf("Error mapping EPT page in guest %e\n", ret);
  8003ef:	8b 45 a4             	mov    -0x5c(%rbp),%eax
  8003f2:	89 c6                	mov    %eax,%esi
  8003f4:	48 bf 80 47 80 00 00 	movabs $0x804780,%rdi
  8003fb:	00 00 00 
  8003fe:	b8 00 00 00 00       	mov    $0x0,%eax
  800403:	48 ba a8 08 80 00 00 	movabs $0x8008a8,%rdx
  80040a:	00 00 00 
  80040d:	ff d2                	callq  *%rdx
			close(fd);
  80040f:	8b 45 bc             	mov    -0x44(%rbp),%eax
  800412:	89 c7                	mov    %eax,%edi
  800414:	48 b8 60 25 80 00 00 	movabs $0x802560,%rax
  80041b:	00 00 00 
  80041e:	ff d0                	callq  *%rax
			return ret;
  800420:	8b 45 a4             	mov    -0x5c(%rbp),%eax
  800423:	eb 33                	jmp    800458 <copy_guest_kern_gpa+0x241>
	// point the program header struct at the location indicated by the elf header
	ph = (struct Proghdr* ) (elf_buf + elf->e_phoff);

	// for every entry in the program header table, map the corresponding entry of the file 
	// into the guest's physical address space
	for (i = 0; i < elf->e_phnum; i++, ph++) {
  800425:	83 45 cc 01          	addl   $0x1,-0x34(%rbp)
  800429:	48 83 45 c0 38       	addq   $0x38,-0x40(%rbp)
  80042e:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800432:	0f b7 40 38          	movzwl 0x38(%rax),%eax
  800436:	0f b7 c0             	movzwl %ax,%eax
  800439:	3b 45 cc             	cmp    -0x34(%rbp),%eax
  80043c:	0f 8f 67 ff ff ff    	jg     8003a9 <copy_guest_kern_gpa+0x192>
			close(fd);
			return ret;
		}
	}

	close(fd);
  800442:	8b 45 bc             	mov    -0x44(%rbp),%eax
  800445:	89 c7                	mov    %eax,%edi
  800447:	48 b8 60 25 80 00 00 	movabs $0x802560,%rax
  80044e:	00 00 00 
  800451:	ff d0                	callq  *%rax
	return 0;
  800453:	b8 00 00 00 00       	mov    $0x0,%eax
  800458:	48 89 dc             	mov    %rbx,%rsp
}
  80045b:	48 8d 65 d8          	lea    -0x28(%rbp),%rsp
  80045f:	5b                   	pop    %rbx
  800460:	41 5c                	pop    %r12
  800462:	41 5d                	pop    %r13
  800464:	41 5e                	pop    %r14
  800466:	41 5f                	pop    %r15
  800468:	5d                   	pop    %rbp
  800469:	c3                   	retq   

000000000080046a <umain>:

void
umain(int argc, char **argv) {
  80046a:	55                   	push   %rbp
  80046b:	48 89 e5             	mov    %rsp,%rbp
  80046e:	48 83 ec 60          	sub    $0x60,%rsp
  800472:	89 7d ac             	mov    %edi,-0x54(%rbp)
  800475:	48 89 75 a0          	mov    %rsi,-0x60(%rbp)
	int ret;
	envid_t guest;
	char filename_buffer[50];	//buffer to save the path 
	int vmdisk_number;
	int r;
	if ((ret = sys_env_mkguest( GUEST_MEM_SZ, JOS_ENTRY )) < 0) {
  800479:	be 00 70 00 00       	mov    $0x7000,%esi
  80047e:	bf 00 00 00 01       	mov    $0x1000000,%edi
  800483:	48 b8 22 21 80 00 00 	movabs $0x802122,%rax
  80048a:	00 00 00 
  80048d:	ff d0                	callq  *%rax
  80048f:	89 45 fc             	mov    %eax,-0x4(%rbp)
  800492:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  800496:	79 2c                	jns    8004c4 <umain+0x5a>
		cprintf("Error creating a guest OS env: %e\n", ret );
  800498:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80049b:	89 c6                	mov    %eax,%esi
  80049d:	48 bf a8 47 80 00 00 	movabs $0x8047a8,%rdi
  8004a4:	00 00 00 
  8004a7:	b8 00 00 00 00       	mov    $0x0,%eax
  8004ac:	48 ba a8 08 80 00 00 	movabs $0x8008a8,%rdx
  8004b3:	00 00 00 
  8004b6:	ff d2                	callq  *%rdx
		exit();
  8004b8:	48 b8 60 07 80 00 00 	movabs $0x800760,%rax
  8004bf:	00 00 00 
  8004c2:	ff d0                	callq  *%rax
	}
	guest = ret;
  8004c4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004c7:	89 45 f8             	mov    %eax,-0x8(%rbp)

	// Copy the guest kernel code into guest phys mem.
	if((ret = copy_guest_kern_gpa(guest, GUEST_KERN)) < 0) {
  8004ca:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8004cd:	48 be cb 47 80 00 00 	movabs $0x8047cb,%rsi
  8004d4:	00 00 00 
  8004d7:	89 c7                	mov    %eax,%edi
  8004d9:	48 b8 17 02 80 00 00 	movabs $0x800217,%rax
  8004e0:	00 00 00 
  8004e3:	ff d0                	callq  *%rax
  8004e5:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8004e8:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004ec:	79 2c                	jns    80051a <umain+0xb0>
		cprintf("Error copying page into the guest - %d\n.", ret);
  8004ee:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004f1:	89 c6                	mov    %eax,%esi
  8004f3:	48 bf d8 47 80 00 00 	movabs $0x8047d8,%rdi
  8004fa:	00 00 00 
  8004fd:	b8 00 00 00 00       	mov    $0x0,%eax
  800502:	48 ba a8 08 80 00 00 	movabs $0x8008a8,%rdx
  800509:	00 00 00 
  80050c:	ff d2                	callq  *%rdx
		exit();
  80050e:	48 b8 60 07 80 00 00 	movabs $0x800760,%rax
  800515:	00 00 00 
  800518:	ff d0                	callq  *%rax
	}

	// Now copy the bootloader.
	int fd;
	if ((fd = open( GUEST_BOOT, O_RDONLY)) < 0 ) {
  80051a:	be 00 00 00 00       	mov    $0x0,%esi
  80051f:	48 bf 01 48 80 00 00 	movabs $0x804801,%rdi
  800526:	00 00 00 
  800529:	48 b8 58 2c 80 00 00 	movabs $0x802c58,%rax
  800530:	00 00 00 
  800533:	ff d0                	callq  *%rax
  800535:	89 45 f4             	mov    %eax,-0xc(%rbp)
  800538:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  80053c:	79 36                	jns    800574 <umain+0x10a>
		cprintf("open %s for read: %e\n", GUEST_BOOT, fd );
  80053e:	8b 45 f4             	mov    -0xc(%rbp),%eax
  800541:	89 c2                	mov    %eax,%edx
  800543:	48 be 01 48 80 00 00 	movabs $0x804801,%rsi
  80054a:	00 00 00 
  80054d:	48 bf 0b 48 80 00 00 	movabs $0x80480b,%rdi
  800554:	00 00 00 
  800557:	b8 00 00 00 00       	mov    $0x0,%eax
  80055c:	48 b9 a8 08 80 00 00 	movabs $0x8008a8,%rcx
  800563:	00 00 00 
  800566:	ff d1                	callq  *%rcx
		exit();
  800568:	48 b8 60 07 80 00 00 	movabs $0x800760,%rax
  80056f:	00 00 00 
  800572:	ff d0                	callq  *%rax
	}

	// sizeof(bootloader) < 512.
	if ((ret = map_in_guest(guest, JOS_ENTRY, 512, fd, 512, 0)) < 0) {
  800574:	8b 55 f4             	mov    -0xc(%rbp),%edx
  800577:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80057a:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  800580:	41 b8 00 02 00 00    	mov    $0x200,%r8d
  800586:	89 d1                	mov    %edx,%ecx
  800588:	ba 00 02 00 00       	mov    $0x200,%edx
  80058d:	be 00 70 00 00       	mov    $0x7000,%esi
  800592:	89 c7                	mov    %eax,%edi
  800594:	48 b8 43 00 80 00 00 	movabs $0x800043,%rax
  80059b:	00 00 00 
  80059e:	ff d0                	callq  *%rax
  8005a0:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8005a3:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8005a7:	79 2c                	jns    8005d5 <umain+0x16b>
		cprintf("Error mapping bootloader into the guest - %d\n.", ret);
  8005a9:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8005ac:	89 c6                	mov    %eax,%esi
  8005ae:	48 bf 28 48 80 00 00 	movabs $0x804828,%rdi
  8005b5:	00 00 00 
  8005b8:	b8 00 00 00 00       	mov    $0x0,%eax
  8005bd:	48 ba a8 08 80 00 00 	movabs $0x8008a8,%rdx
  8005c4:	00 00 00 
  8005c7:	ff d2                	callq  *%rdx
		exit();
  8005c9:	48 b8 60 07 80 00 00 	movabs $0x800760,%rax
  8005d0:	00 00 00 
  8005d3:	ff d0                	callq  *%rax
	}
#ifndef VMM_GUEST	
	sys_vmx_incr_vmdisk_number();	//increase the vmdisk number
  8005d5:	b8 00 00 00 00       	mov    $0x0,%eax
  8005da:	48 ba 2c 22 80 00 00 	movabs $0x80222c,%rdx
  8005e1:	00 00 00 
  8005e4:	ff d2                	callq  *%rdx
	//create a new guest disk image
	
	vmdisk_number = sys_vmx_get_vmdisk_number();
  8005e6:	b8 00 00 00 00       	mov    $0x0,%eax
  8005eb:	48 ba ee 21 80 00 00 	movabs $0x8021ee,%rdx
  8005f2:	00 00 00 
  8005f5:	ff d2                	callq  *%rdx
  8005f7:	89 45 f0             	mov    %eax,-0x10(%rbp)
	snprintf(filename_buffer, 50, "/vmm/fs%d.img", vmdisk_number);
  8005fa:	8b 55 f0             	mov    -0x10(%rbp),%edx
  8005fd:	48 8d 45 b0          	lea    -0x50(%rbp),%rax
  800601:	89 d1                	mov    %edx,%ecx
  800603:	48 ba 57 48 80 00 00 	movabs $0x804857,%rdx
  80060a:	00 00 00 
  80060d:	be 32 00 00 00       	mov    $0x32,%esi
  800612:	48 89 c7             	mov    %rax,%rdi
  800615:	b8 00 00 00 00       	mov    $0x0,%eax
  80061a:	49 b8 10 13 80 00 00 	movabs $0x801310,%r8
  800621:	00 00 00 
  800624:	41 ff d0             	callq  *%r8
	
	cprintf("Creating a new virtual HDD at /vmm/fs%d.img\n", vmdisk_number);
  800627:	8b 45 f0             	mov    -0x10(%rbp),%eax
  80062a:	89 c6                	mov    %eax,%esi
  80062c:	48 bf 68 48 80 00 00 	movabs $0x804868,%rdi
  800633:	00 00 00 
  800636:	b8 00 00 00 00       	mov    $0x0,%eax
  80063b:	48 ba a8 08 80 00 00 	movabs $0x8008a8,%rdx
  800642:	00 00 00 
  800645:	ff d2                	callq  *%rdx
        r = copy("vmm/clean-fs.img", filename_buffer);
  800647:	48 8d 45 b0          	lea    -0x50(%rbp),%rax
  80064b:	48 89 c6             	mov    %rax,%rsi
  80064e:	48 bf 95 48 80 00 00 	movabs $0x804895,%rdi
  800655:	00 00 00 
  800658:	48 b8 ba 30 80 00 00 	movabs $0x8030ba,%rax
  80065f:	00 00 00 
  800662:	ff d0                	callq  *%rax
  800664:	89 45 ec             	mov    %eax,-0x14(%rbp)
        
        if (r < 0) {
  800667:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  80066b:	79 2c                	jns    800699 <umain+0x22f>
        	cprintf("Create new virtual HDD failed: %e\n", r);
  80066d:	8b 45 ec             	mov    -0x14(%rbp),%eax
  800670:	89 c6                	mov    %eax,%esi
  800672:	48 bf a8 48 80 00 00 	movabs $0x8048a8,%rdi
  800679:	00 00 00 
  80067c:	b8 00 00 00 00       	mov    $0x0,%eax
  800681:	48 ba a8 08 80 00 00 	movabs $0x8008a8,%rdx
  800688:	00 00 00 
  80068b:	ff d2                	callq  *%rdx
        	exit();
  80068d:	48 b8 60 07 80 00 00 	movabs $0x800760,%rax
  800694:	00 00 00 
  800697:	ff d0                	callq  *%rax
        }
        
        cprintf("Create VHD finished\n");
  800699:	48 bf cb 48 80 00 00 	movabs $0x8048cb,%rdi
  8006a0:	00 00 00 
  8006a3:	b8 00 00 00 00       	mov    $0x0,%eax
  8006a8:	48 ba a8 08 80 00 00 	movabs $0x8008a8,%rdx
  8006af:	00 00 00 
  8006b2:	ff d2                	callq  *%rdx
#endif
	// Mark the guest as runnable.
	sys_env_set_status(guest, ENV_RUNNABLE);
  8006b4:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8006b7:	be 02 00 00 00       	mov    $0x2,%esi
  8006bc:	89 c7                	mov    %eax,%edi
  8006be:	48 b8 81 1e 80 00 00 	movabs $0x801e81,%rax
  8006c5:	00 00 00 
  8006c8:	ff d0                	callq  *%rax
	wait(guest);
  8006ca:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8006cd:	89 c7                	mov    %eax,%edi
  8006cf:	48 b8 6a 40 80 00 00 	movabs $0x80406a,%rax
  8006d6:	00 00 00 
  8006d9:	ff d0                	callq  *%rax
}
  8006db:	c9                   	leaveq 
  8006dc:	c3                   	retq   

00000000008006dd <libmain>:
  8006dd:	55                   	push   %rbp
  8006de:	48 89 e5             	mov    %rsp,%rbp
  8006e1:	48 83 ec 10          	sub    $0x10,%rsp
  8006e5:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8006e8:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8006ec:	48 b8 10 1d 80 00 00 	movabs $0x801d10,%rax
  8006f3:	00 00 00 
  8006f6:	ff d0                	callq  *%rax
  8006f8:	25 ff 03 00 00       	and    $0x3ff,%eax
  8006fd:	48 98                	cltq   
  8006ff:	48 69 d0 68 01 00 00 	imul   $0x168,%rax,%rdx
  800706:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  80070d:	00 00 00 
  800710:	48 01 c2             	add    %rax,%rdx
  800713:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  80071a:	00 00 00 
  80071d:	48 89 10             	mov    %rdx,(%rax)
  800720:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  800724:	7e 14                	jle    80073a <libmain+0x5d>
  800726:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80072a:	48 8b 10             	mov    (%rax),%rdx
  80072d:	48 b8 00 60 80 00 00 	movabs $0x806000,%rax
  800734:	00 00 00 
  800737:	48 89 10             	mov    %rdx,(%rax)
  80073a:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80073e:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800741:	48 89 d6             	mov    %rdx,%rsi
  800744:	89 c7                	mov    %eax,%edi
  800746:	48 b8 6a 04 80 00 00 	movabs $0x80046a,%rax
  80074d:	00 00 00 
  800750:	ff d0                	callq  *%rax
  800752:	48 b8 60 07 80 00 00 	movabs $0x800760,%rax
  800759:	00 00 00 
  80075c:	ff d0                	callq  *%rax
  80075e:	c9                   	leaveq 
  80075f:	c3                   	retq   

0000000000800760 <exit>:
  800760:	55                   	push   %rbp
  800761:	48 89 e5             	mov    %rsp,%rbp
  800764:	48 b8 ab 25 80 00 00 	movabs $0x8025ab,%rax
  80076b:	00 00 00 
  80076e:	ff d0                	callq  *%rax
  800770:	bf 00 00 00 00       	mov    $0x0,%edi
  800775:	48 b8 cc 1c 80 00 00 	movabs $0x801ccc,%rax
  80077c:	00 00 00 
  80077f:	ff d0                	callq  *%rax
  800781:	5d                   	pop    %rbp
  800782:	c3                   	retq   

0000000000800783 <putch>:
  800783:	55                   	push   %rbp
  800784:	48 89 e5             	mov    %rsp,%rbp
  800787:	48 83 ec 10          	sub    $0x10,%rsp
  80078b:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80078e:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  800792:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800796:	8b 00                	mov    (%rax),%eax
  800798:	8d 48 01             	lea    0x1(%rax),%ecx
  80079b:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80079f:	89 0a                	mov    %ecx,(%rdx)
  8007a1:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8007a4:	89 d1                	mov    %edx,%ecx
  8007a6:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8007aa:	48 98                	cltq   
  8007ac:	88 4c 02 08          	mov    %cl,0x8(%rdx,%rax,1)
  8007b0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8007b4:	8b 00                	mov    (%rax),%eax
  8007b6:	3d ff 00 00 00       	cmp    $0xff,%eax
  8007bb:	75 2c                	jne    8007e9 <putch+0x66>
  8007bd:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8007c1:	8b 00                	mov    (%rax),%eax
  8007c3:	48 98                	cltq   
  8007c5:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8007c9:	48 83 c2 08          	add    $0x8,%rdx
  8007cd:	48 89 c6             	mov    %rax,%rsi
  8007d0:	48 89 d7             	mov    %rdx,%rdi
  8007d3:	48 b8 44 1c 80 00 00 	movabs $0x801c44,%rax
  8007da:	00 00 00 
  8007dd:	ff d0                	callq  *%rax
  8007df:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8007e3:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
  8007e9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8007ed:	8b 40 04             	mov    0x4(%rax),%eax
  8007f0:	8d 50 01             	lea    0x1(%rax),%edx
  8007f3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8007f7:	89 50 04             	mov    %edx,0x4(%rax)
  8007fa:	c9                   	leaveq 
  8007fb:	c3                   	retq   

00000000008007fc <vcprintf>:
  8007fc:	55                   	push   %rbp
  8007fd:	48 89 e5             	mov    %rsp,%rbp
  800800:	48 81 ec 40 01 00 00 	sub    $0x140,%rsp
  800807:	48 89 bd c8 fe ff ff 	mov    %rdi,-0x138(%rbp)
  80080e:	48 89 b5 c0 fe ff ff 	mov    %rsi,-0x140(%rbp)
  800815:	48 8d 85 d8 fe ff ff 	lea    -0x128(%rbp),%rax
  80081c:	48 8b 95 c0 fe ff ff 	mov    -0x140(%rbp),%rdx
  800823:	48 8b 0a             	mov    (%rdx),%rcx
  800826:	48 89 08             	mov    %rcx,(%rax)
  800829:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  80082d:	48 89 48 08          	mov    %rcx,0x8(%rax)
  800831:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  800835:	48 89 50 10          	mov    %rdx,0x10(%rax)
  800839:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%rbp)
  800840:	00 00 00 
  800843:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%rbp)
  80084a:	00 00 00 
  80084d:	48 8d 8d d8 fe ff ff 	lea    -0x128(%rbp),%rcx
  800854:	48 8b 95 c8 fe ff ff 	mov    -0x138(%rbp),%rdx
  80085b:	48 8d 85 f0 fe ff ff 	lea    -0x110(%rbp),%rax
  800862:	48 89 c6             	mov    %rax,%rsi
  800865:	48 bf 83 07 80 00 00 	movabs $0x800783,%rdi
  80086c:	00 00 00 
  80086f:	48 b8 5b 0c 80 00 00 	movabs $0x800c5b,%rax
  800876:	00 00 00 
  800879:	ff d0                	callq  *%rax
  80087b:	8b 85 f0 fe ff ff    	mov    -0x110(%rbp),%eax
  800881:	48 98                	cltq   
  800883:	48 8d 95 f0 fe ff ff 	lea    -0x110(%rbp),%rdx
  80088a:	48 83 c2 08          	add    $0x8,%rdx
  80088e:	48 89 c6             	mov    %rax,%rsi
  800891:	48 89 d7             	mov    %rdx,%rdi
  800894:	48 b8 44 1c 80 00 00 	movabs $0x801c44,%rax
  80089b:	00 00 00 
  80089e:	ff d0                	callq  *%rax
  8008a0:	8b 85 f4 fe ff ff    	mov    -0x10c(%rbp),%eax
  8008a6:	c9                   	leaveq 
  8008a7:	c3                   	retq   

00000000008008a8 <cprintf>:
  8008a8:	55                   	push   %rbp
  8008a9:	48 89 e5             	mov    %rsp,%rbp
  8008ac:	48 81 ec 00 01 00 00 	sub    $0x100,%rsp
  8008b3:	48 89 b5 58 ff ff ff 	mov    %rsi,-0xa8(%rbp)
  8008ba:	48 89 95 60 ff ff ff 	mov    %rdx,-0xa0(%rbp)
  8008c1:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  8008c8:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  8008cf:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  8008d6:	84 c0                	test   %al,%al
  8008d8:	74 20                	je     8008fa <cprintf+0x52>
  8008da:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  8008de:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  8008e2:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  8008e6:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  8008ea:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  8008ee:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  8008f2:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  8008f6:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  8008fa:	48 89 bd 08 ff ff ff 	mov    %rdi,-0xf8(%rbp)
  800901:	c7 85 30 ff ff ff 08 	movl   $0x8,-0xd0(%rbp)
  800908:	00 00 00 
  80090b:	c7 85 34 ff ff ff 30 	movl   $0x30,-0xcc(%rbp)
  800912:	00 00 00 
  800915:	48 8d 45 10          	lea    0x10(%rbp),%rax
  800919:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  800920:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  800927:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  80092e:	48 8d 85 18 ff ff ff 	lea    -0xe8(%rbp),%rax
  800935:	48 8d 95 30 ff ff ff 	lea    -0xd0(%rbp),%rdx
  80093c:	48 8b 0a             	mov    (%rdx),%rcx
  80093f:	48 89 08             	mov    %rcx,(%rax)
  800942:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  800946:	48 89 48 08          	mov    %rcx,0x8(%rax)
  80094a:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  80094e:	48 89 50 10          	mov    %rdx,0x10(%rax)
  800952:	48 8d 95 18 ff ff ff 	lea    -0xe8(%rbp),%rdx
  800959:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  800960:	48 89 d6             	mov    %rdx,%rsi
  800963:	48 89 c7             	mov    %rax,%rdi
  800966:	48 b8 fc 07 80 00 00 	movabs $0x8007fc,%rax
  80096d:	00 00 00 
  800970:	ff d0                	callq  *%rax
  800972:	89 85 4c ff ff ff    	mov    %eax,-0xb4(%rbp)
  800978:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
  80097e:	c9                   	leaveq 
  80097f:	c3                   	retq   

0000000000800980 <printnum>:
  800980:	55                   	push   %rbp
  800981:	48 89 e5             	mov    %rsp,%rbp
  800984:	53                   	push   %rbx
  800985:	48 83 ec 38          	sub    $0x38,%rsp
  800989:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80098d:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  800991:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  800995:	89 4d d4             	mov    %ecx,-0x2c(%rbp)
  800998:	44 89 45 d0          	mov    %r8d,-0x30(%rbp)
  80099c:	44 89 4d cc          	mov    %r9d,-0x34(%rbp)
  8009a0:	8b 45 d4             	mov    -0x2c(%rbp),%eax
  8009a3:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  8009a7:	77 3b                	ja     8009e4 <printnum+0x64>
  8009a9:	8b 45 d0             	mov    -0x30(%rbp),%eax
  8009ac:	44 8d 40 ff          	lea    -0x1(%rax),%r8d
  8009b0:	8b 5d d4             	mov    -0x2c(%rbp),%ebx
  8009b3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8009b7:	ba 00 00 00 00       	mov    $0x0,%edx
  8009bc:	48 f7 f3             	div    %rbx
  8009bf:	48 89 c2             	mov    %rax,%rdx
  8009c2:	8b 7d cc             	mov    -0x34(%rbp),%edi
  8009c5:	8b 4d d4             	mov    -0x2c(%rbp),%ecx
  8009c8:	48 8b 75 e0          	mov    -0x20(%rbp),%rsi
  8009cc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8009d0:	41 89 f9             	mov    %edi,%r9d
  8009d3:	48 89 c7             	mov    %rax,%rdi
  8009d6:	48 b8 80 09 80 00 00 	movabs $0x800980,%rax
  8009dd:	00 00 00 
  8009e0:	ff d0                	callq  *%rax
  8009e2:	eb 1e                	jmp    800a02 <printnum+0x82>
  8009e4:	eb 12                	jmp    8009f8 <printnum+0x78>
  8009e6:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  8009ea:	8b 55 cc             	mov    -0x34(%rbp),%edx
  8009ed:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8009f1:	48 89 ce             	mov    %rcx,%rsi
  8009f4:	89 d7                	mov    %edx,%edi
  8009f6:	ff d0                	callq  *%rax
  8009f8:	83 6d d0 01          	subl   $0x1,-0x30(%rbp)
  8009fc:	83 7d d0 00          	cmpl   $0x0,-0x30(%rbp)
  800a00:	7f e4                	jg     8009e6 <printnum+0x66>
  800a02:	8b 4d d4             	mov    -0x2c(%rbp),%ecx
  800a05:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800a09:	ba 00 00 00 00       	mov    $0x0,%edx
  800a0e:	48 f7 f1             	div    %rcx
  800a11:	48 89 d0             	mov    %rdx,%rax
  800a14:	48 ba f0 4a 80 00 00 	movabs $0x804af0,%rdx
  800a1b:	00 00 00 
  800a1e:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
  800a22:	0f be d0             	movsbl %al,%edx
  800a25:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  800a29:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800a2d:	48 89 ce             	mov    %rcx,%rsi
  800a30:	89 d7                	mov    %edx,%edi
  800a32:	ff d0                	callq  *%rax
  800a34:	48 83 c4 38          	add    $0x38,%rsp
  800a38:	5b                   	pop    %rbx
  800a39:	5d                   	pop    %rbp
  800a3a:	c3                   	retq   

0000000000800a3b <getuint>:
  800a3b:	55                   	push   %rbp
  800a3c:	48 89 e5             	mov    %rsp,%rbp
  800a3f:	48 83 ec 1c          	sub    $0x1c,%rsp
  800a43:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800a47:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  800a4a:	83 7d e4 01          	cmpl   $0x1,-0x1c(%rbp)
  800a4e:	7e 52                	jle    800aa2 <getuint+0x67>
  800a50:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800a54:	8b 00                	mov    (%rax),%eax
  800a56:	83 f8 30             	cmp    $0x30,%eax
  800a59:	73 24                	jae    800a7f <getuint+0x44>
  800a5b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800a5f:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800a63:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800a67:	8b 00                	mov    (%rax),%eax
  800a69:	89 c0                	mov    %eax,%eax
  800a6b:	48 01 d0             	add    %rdx,%rax
  800a6e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800a72:	8b 12                	mov    (%rdx),%edx
  800a74:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800a77:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800a7b:	89 0a                	mov    %ecx,(%rdx)
  800a7d:	eb 17                	jmp    800a96 <getuint+0x5b>
  800a7f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800a83:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800a87:	48 89 d0             	mov    %rdx,%rax
  800a8a:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800a8e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800a92:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800a96:	48 8b 00             	mov    (%rax),%rax
  800a99:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800a9d:	e9 a3 00 00 00       	jmpq   800b45 <getuint+0x10a>
  800aa2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  800aa6:	74 4f                	je     800af7 <getuint+0xbc>
  800aa8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800aac:	8b 00                	mov    (%rax),%eax
  800aae:	83 f8 30             	cmp    $0x30,%eax
  800ab1:	73 24                	jae    800ad7 <getuint+0x9c>
  800ab3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800ab7:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800abb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800abf:	8b 00                	mov    (%rax),%eax
  800ac1:	89 c0                	mov    %eax,%eax
  800ac3:	48 01 d0             	add    %rdx,%rax
  800ac6:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800aca:	8b 12                	mov    (%rdx),%edx
  800acc:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800acf:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800ad3:	89 0a                	mov    %ecx,(%rdx)
  800ad5:	eb 17                	jmp    800aee <getuint+0xb3>
  800ad7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800adb:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800adf:	48 89 d0             	mov    %rdx,%rax
  800ae2:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800ae6:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800aea:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800aee:	48 8b 00             	mov    (%rax),%rax
  800af1:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800af5:	eb 4e                	jmp    800b45 <getuint+0x10a>
  800af7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800afb:	8b 00                	mov    (%rax),%eax
  800afd:	83 f8 30             	cmp    $0x30,%eax
  800b00:	73 24                	jae    800b26 <getuint+0xeb>
  800b02:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b06:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800b0a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b0e:	8b 00                	mov    (%rax),%eax
  800b10:	89 c0                	mov    %eax,%eax
  800b12:	48 01 d0             	add    %rdx,%rax
  800b15:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b19:	8b 12                	mov    (%rdx),%edx
  800b1b:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800b1e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b22:	89 0a                	mov    %ecx,(%rdx)
  800b24:	eb 17                	jmp    800b3d <getuint+0x102>
  800b26:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b2a:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800b2e:	48 89 d0             	mov    %rdx,%rax
  800b31:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800b35:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b39:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800b3d:	8b 00                	mov    (%rax),%eax
  800b3f:	89 c0                	mov    %eax,%eax
  800b41:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800b45:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800b49:	c9                   	leaveq 
  800b4a:	c3                   	retq   

0000000000800b4b <getint>:
  800b4b:	55                   	push   %rbp
  800b4c:	48 89 e5             	mov    %rsp,%rbp
  800b4f:	48 83 ec 1c          	sub    $0x1c,%rsp
  800b53:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800b57:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  800b5a:	83 7d e4 01          	cmpl   $0x1,-0x1c(%rbp)
  800b5e:	7e 52                	jle    800bb2 <getint+0x67>
  800b60:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b64:	8b 00                	mov    (%rax),%eax
  800b66:	83 f8 30             	cmp    $0x30,%eax
  800b69:	73 24                	jae    800b8f <getint+0x44>
  800b6b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b6f:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800b73:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b77:	8b 00                	mov    (%rax),%eax
  800b79:	89 c0                	mov    %eax,%eax
  800b7b:	48 01 d0             	add    %rdx,%rax
  800b7e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b82:	8b 12                	mov    (%rdx),%edx
  800b84:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800b87:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b8b:	89 0a                	mov    %ecx,(%rdx)
  800b8d:	eb 17                	jmp    800ba6 <getint+0x5b>
  800b8f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b93:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800b97:	48 89 d0             	mov    %rdx,%rax
  800b9a:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800b9e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800ba2:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800ba6:	48 8b 00             	mov    (%rax),%rax
  800ba9:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800bad:	e9 a3 00 00 00       	jmpq   800c55 <getint+0x10a>
  800bb2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  800bb6:	74 4f                	je     800c07 <getint+0xbc>
  800bb8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800bbc:	8b 00                	mov    (%rax),%eax
  800bbe:	83 f8 30             	cmp    $0x30,%eax
  800bc1:	73 24                	jae    800be7 <getint+0x9c>
  800bc3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800bc7:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800bcb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800bcf:	8b 00                	mov    (%rax),%eax
  800bd1:	89 c0                	mov    %eax,%eax
  800bd3:	48 01 d0             	add    %rdx,%rax
  800bd6:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800bda:	8b 12                	mov    (%rdx),%edx
  800bdc:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800bdf:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800be3:	89 0a                	mov    %ecx,(%rdx)
  800be5:	eb 17                	jmp    800bfe <getint+0xb3>
  800be7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800beb:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800bef:	48 89 d0             	mov    %rdx,%rax
  800bf2:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800bf6:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800bfa:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800bfe:	48 8b 00             	mov    (%rax),%rax
  800c01:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800c05:	eb 4e                	jmp    800c55 <getint+0x10a>
  800c07:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c0b:	8b 00                	mov    (%rax),%eax
  800c0d:	83 f8 30             	cmp    $0x30,%eax
  800c10:	73 24                	jae    800c36 <getint+0xeb>
  800c12:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c16:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800c1a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c1e:	8b 00                	mov    (%rax),%eax
  800c20:	89 c0                	mov    %eax,%eax
  800c22:	48 01 d0             	add    %rdx,%rax
  800c25:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c29:	8b 12                	mov    (%rdx),%edx
  800c2b:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800c2e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c32:	89 0a                	mov    %ecx,(%rdx)
  800c34:	eb 17                	jmp    800c4d <getint+0x102>
  800c36:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c3a:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800c3e:	48 89 d0             	mov    %rdx,%rax
  800c41:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800c45:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c49:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800c4d:	8b 00                	mov    (%rax),%eax
  800c4f:	48 98                	cltq   
  800c51:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800c55:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800c59:	c9                   	leaveq 
  800c5a:	c3                   	retq   

0000000000800c5b <vprintfmt>:
  800c5b:	55                   	push   %rbp
  800c5c:	48 89 e5             	mov    %rsp,%rbp
  800c5f:	41 54                	push   %r12
  800c61:	53                   	push   %rbx
  800c62:	48 83 ec 60          	sub    $0x60,%rsp
  800c66:	48 89 7d a8          	mov    %rdi,-0x58(%rbp)
  800c6a:	48 89 75 a0          	mov    %rsi,-0x60(%rbp)
  800c6e:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  800c72:	48 89 4d 90          	mov    %rcx,-0x70(%rbp)
  800c76:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  800c7a:	48 8b 55 90          	mov    -0x70(%rbp),%rdx
  800c7e:	48 8b 0a             	mov    (%rdx),%rcx
  800c81:	48 89 08             	mov    %rcx,(%rax)
  800c84:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  800c88:	48 89 48 08          	mov    %rcx,0x8(%rax)
  800c8c:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  800c90:	48 89 50 10          	mov    %rdx,0x10(%rax)
  800c94:	eb 17                	jmp    800cad <vprintfmt+0x52>
  800c96:	85 db                	test   %ebx,%ebx
  800c98:	0f 84 cc 04 00 00    	je     80116a <vprintfmt+0x50f>
  800c9e:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800ca2:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800ca6:	48 89 d6             	mov    %rdx,%rsi
  800ca9:	89 df                	mov    %ebx,%edi
  800cab:	ff d0                	callq  *%rax
  800cad:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800cb1:	48 8d 50 01          	lea    0x1(%rax),%rdx
  800cb5:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  800cb9:	0f b6 00             	movzbl (%rax),%eax
  800cbc:	0f b6 d8             	movzbl %al,%ebx
  800cbf:	83 fb 25             	cmp    $0x25,%ebx
  800cc2:	75 d2                	jne    800c96 <vprintfmt+0x3b>
  800cc4:	c6 45 d3 20          	movb   $0x20,-0x2d(%rbp)
  800cc8:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%rbp)
  800ccf:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%rbp)
  800cd6:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%rbp)
  800cdd:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%rbp)
  800ce4:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800ce8:	48 8d 50 01          	lea    0x1(%rax),%rdx
  800cec:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  800cf0:	0f b6 00             	movzbl (%rax),%eax
  800cf3:	0f b6 d8             	movzbl %al,%ebx
  800cf6:	8d 43 dd             	lea    -0x23(%rbx),%eax
  800cf9:	83 f8 55             	cmp    $0x55,%eax
  800cfc:	0f 87 34 04 00 00    	ja     801136 <vprintfmt+0x4db>
  800d02:	89 c0                	mov    %eax,%eax
  800d04:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  800d0b:	00 
  800d0c:	48 b8 18 4b 80 00 00 	movabs $0x804b18,%rax
  800d13:	00 00 00 
  800d16:	48 01 d0             	add    %rdx,%rax
  800d19:	48 8b 00             	mov    (%rax),%rax
  800d1c:	ff e0                	jmpq   *%rax
  800d1e:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%rbp)
  800d22:	eb c0                	jmp    800ce4 <vprintfmt+0x89>
  800d24:	c6 45 d3 30          	movb   $0x30,-0x2d(%rbp)
  800d28:	eb ba                	jmp    800ce4 <vprintfmt+0x89>
  800d2a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%rbp)
  800d31:	8b 55 d8             	mov    -0x28(%rbp),%edx
  800d34:	89 d0                	mov    %edx,%eax
  800d36:	c1 e0 02             	shl    $0x2,%eax
  800d39:	01 d0                	add    %edx,%eax
  800d3b:	01 c0                	add    %eax,%eax
  800d3d:	01 d8                	add    %ebx,%eax
  800d3f:	83 e8 30             	sub    $0x30,%eax
  800d42:	89 45 d8             	mov    %eax,-0x28(%rbp)
  800d45:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800d49:	0f b6 00             	movzbl (%rax),%eax
  800d4c:	0f be d8             	movsbl %al,%ebx
  800d4f:	83 fb 2f             	cmp    $0x2f,%ebx
  800d52:	7e 0c                	jle    800d60 <vprintfmt+0x105>
  800d54:	83 fb 39             	cmp    $0x39,%ebx
  800d57:	7f 07                	jg     800d60 <vprintfmt+0x105>
  800d59:	48 83 45 98 01       	addq   $0x1,-0x68(%rbp)
  800d5e:	eb d1                	jmp    800d31 <vprintfmt+0xd6>
  800d60:	eb 58                	jmp    800dba <vprintfmt+0x15f>
  800d62:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800d65:	83 f8 30             	cmp    $0x30,%eax
  800d68:	73 17                	jae    800d81 <vprintfmt+0x126>
  800d6a:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800d6e:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800d71:	89 c0                	mov    %eax,%eax
  800d73:	48 01 d0             	add    %rdx,%rax
  800d76:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800d79:	83 c2 08             	add    $0x8,%edx
  800d7c:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800d7f:	eb 0f                	jmp    800d90 <vprintfmt+0x135>
  800d81:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800d85:	48 89 d0             	mov    %rdx,%rax
  800d88:	48 83 c2 08          	add    $0x8,%rdx
  800d8c:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800d90:	8b 00                	mov    (%rax),%eax
  800d92:	89 45 d8             	mov    %eax,-0x28(%rbp)
  800d95:	eb 23                	jmp    800dba <vprintfmt+0x15f>
  800d97:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800d9b:	79 0c                	jns    800da9 <vprintfmt+0x14e>
  800d9d:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%rbp)
  800da4:	e9 3b ff ff ff       	jmpq   800ce4 <vprintfmt+0x89>
  800da9:	e9 36 ff ff ff       	jmpq   800ce4 <vprintfmt+0x89>
  800dae:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%rbp)
  800db5:	e9 2a ff ff ff       	jmpq   800ce4 <vprintfmt+0x89>
  800dba:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800dbe:	79 12                	jns    800dd2 <vprintfmt+0x177>
  800dc0:	8b 45 d8             	mov    -0x28(%rbp),%eax
  800dc3:	89 45 dc             	mov    %eax,-0x24(%rbp)
  800dc6:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%rbp)
  800dcd:	e9 12 ff ff ff       	jmpq   800ce4 <vprintfmt+0x89>
  800dd2:	e9 0d ff ff ff       	jmpq   800ce4 <vprintfmt+0x89>
  800dd7:	83 45 e0 01          	addl   $0x1,-0x20(%rbp)
  800ddb:	e9 04 ff ff ff       	jmpq   800ce4 <vprintfmt+0x89>
  800de0:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800de3:	83 f8 30             	cmp    $0x30,%eax
  800de6:	73 17                	jae    800dff <vprintfmt+0x1a4>
  800de8:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800dec:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800def:	89 c0                	mov    %eax,%eax
  800df1:	48 01 d0             	add    %rdx,%rax
  800df4:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800df7:	83 c2 08             	add    $0x8,%edx
  800dfa:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800dfd:	eb 0f                	jmp    800e0e <vprintfmt+0x1b3>
  800dff:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800e03:	48 89 d0             	mov    %rdx,%rax
  800e06:	48 83 c2 08          	add    $0x8,%rdx
  800e0a:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800e0e:	8b 10                	mov    (%rax),%edx
  800e10:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  800e14:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800e18:	48 89 ce             	mov    %rcx,%rsi
  800e1b:	89 d7                	mov    %edx,%edi
  800e1d:	ff d0                	callq  *%rax
  800e1f:	e9 40 03 00 00       	jmpq   801164 <vprintfmt+0x509>
  800e24:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800e27:	83 f8 30             	cmp    $0x30,%eax
  800e2a:	73 17                	jae    800e43 <vprintfmt+0x1e8>
  800e2c:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800e30:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800e33:	89 c0                	mov    %eax,%eax
  800e35:	48 01 d0             	add    %rdx,%rax
  800e38:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800e3b:	83 c2 08             	add    $0x8,%edx
  800e3e:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800e41:	eb 0f                	jmp    800e52 <vprintfmt+0x1f7>
  800e43:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800e47:	48 89 d0             	mov    %rdx,%rax
  800e4a:	48 83 c2 08          	add    $0x8,%rdx
  800e4e:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800e52:	8b 18                	mov    (%rax),%ebx
  800e54:	85 db                	test   %ebx,%ebx
  800e56:	79 02                	jns    800e5a <vprintfmt+0x1ff>
  800e58:	f7 db                	neg    %ebx
  800e5a:	83 fb 15             	cmp    $0x15,%ebx
  800e5d:	7f 16                	jg     800e75 <vprintfmt+0x21a>
  800e5f:	48 b8 40 4a 80 00 00 	movabs $0x804a40,%rax
  800e66:	00 00 00 
  800e69:	48 63 d3             	movslq %ebx,%rdx
  800e6c:	4c 8b 24 d0          	mov    (%rax,%rdx,8),%r12
  800e70:	4d 85 e4             	test   %r12,%r12
  800e73:	75 2e                	jne    800ea3 <vprintfmt+0x248>
  800e75:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  800e79:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800e7d:	89 d9                	mov    %ebx,%ecx
  800e7f:	48 ba 01 4b 80 00 00 	movabs $0x804b01,%rdx
  800e86:	00 00 00 
  800e89:	48 89 c7             	mov    %rax,%rdi
  800e8c:	b8 00 00 00 00       	mov    $0x0,%eax
  800e91:	49 b8 73 11 80 00 00 	movabs $0x801173,%r8
  800e98:	00 00 00 
  800e9b:	41 ff d0             	callq  *%r8
  800e9e:	e9 c1 02 00 00       	jmpq   801164 <vprintfmt+0x509>
  800ea3:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  800ea7:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800eab:	4c 89 e1             	mov    %r12,%rcx
  800eae:	48 ba 0a 4b 80 00 00 	movabs $0x804b0a,%rdx
  800eb5:	00 00 00 
  800eb8:	48 89 c7             	mov    %rax,%rdi
  800ebb:	b8 00 00 00 00       	mov    $0x0,%eax
  800ec0:	49 b8 73 11 80 00 00 	movabs $0x801173,%r8
  800ec7:	00 00 00 
  800eca:	41 ff d0             	callq  *%r8
  800ecd:	e9 92 02 00 00       	jmpq   801164 <vprintfmt+0x509>
  800ed2:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800ed5:	83 f8 30             	cmp    $0x30,%eax
  800ed8:	73 17                	jae    800ef1 <vprintfmt+0x296>
  800eda:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800ede:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800ee1:	89 c0                	mov    %eax,%eax
  800ee3:	48 01 d0             	add    %rdx,%rax
  800ee6:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800ee9:	83 c2 08             	add    $0x8,%edx
  800eec:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800eef:	eb 0f                	jmp    800f00 <vprintfmt+0x2a5>
  800ef1:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800ef5:	48 89 d0             	mov    %rdx,%rax
  800ef8:	48 83 c2 08          	add    $0x8,%rdx
  800efc:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800f00:	4c 8b 20             	mov    (%rax),%r12
  800f03:	4d 85 e4             	test   %r12,%r12
  800f06:	75 0a                	jne    800f12 <vprintfmt+0x2b7>
  800f08:	49 bc 0d 4b 80 00 00 	movabs $0x804b0d,%r12
  800f0f:	00 00 00 
  800f12:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800f16:	7e 3f                	jle    800f57 <vprintfmt+0x2fc>
  800f18:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%rbp)
  800f1c:	74 39                	je     800f57 <vprintfmt+0x2fc>
  800f1e:	8b 45 d8             	mov    -0x28(%rbp),%eax
  800f21:	48 98                	cltq   
  800f23:	48 89 c6             	mov    %rax,%rsi
  800f26:	4c 89 e7             	mov    %r12,%rdi
  800f29:	48 b8 1f 14 80 00 00 	movabs $0x80141f,%rax
  800f30:	00 00 00 
  800f33:	ff d0                	callq  *%rax
  800f35:	29 45 dc             	sub    %eax,-0x24(%rbp)
  800f38:	eb 17                	jmp    800f51 <vprintfmt+0x2f6>
  800f3a:	0f be 55 d3          	movsbl -0x2d(%rbp),%edx
  800f3e:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  800f42:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800f46:	48 89 ce             	mov    %rcx,%rsi
  800f49:	89 d7                	mov    %edx,%edi
  800f4b:	ff d0                	callq  *%rax
  800f4d:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  800f51:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800f55:	7f e3                	jg     800f3a <vprintfmt+0x2df>
  800f57:	eb 37                	jmp    800f90 <vprintfmt+0x335>
  800f59:	83 7d d4 00          	cmpl   $0x0,-0x2c(%rbp)
  800f5d:	74 1e                	je     800f7d <vprintfmt+0x322>
  800f5f:	83 fb 1f             	cmp    $0x1f,%ebx
  800f62:	7e 05                	jle    800f69 <vprintfmt+0x30e>
  800f64:	83 fb 7e             	cmp    $0x7e,%ebx
  800f67:	7e 14                	jle    800f7d <vprintfmt+0x322>
  800f69:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800f6d:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800f71:	48 89 d6             	mov    %rdx,%rsi
  800f74:	bf 3f 00 00 00       	mov    $0x3f,%edi
  800f79:	ff d0                	callq  *%rax
  800f7b:	eb 0f                	jmp    800f8c <vprintfmt+0x331>
  800f7d:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800f81:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800f85:	48 89 d6             	mov    %rdx,%rsi
  800f88:	89 df                	mov    %ebx,%edi
  800f8a:	ff d0                	callq  *%rax
  800f8c:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  800f90:	4c 89 e0             	mov    %r12,%rax
  800f93:	4c 8d 60 01          	lea    0x1(%rax),%r12
  800f97:	0f b6 00             	movzbl (%rax),%eax
  800f9a:	0f be d8             	movsbl %al,%ebx
  800f9d:	85 db                	test   %ebx,%ebx
  800f9f:	74 10                	je     800fb1 <vprintfmt+0x356>
  800fa1:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  800fa5:	78 b2                	js     800f59 <vprintfmt+0x2fe>
  800fa7:	83 6d d8 01          	subl   $0x1,-0x28(%rbp)
  800fab:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  800faf:	79 a8                	jns    800f59 <vprintfmt+0x2fe>
  800fb1:	eb 16                	jmp    800fc9 <vprintfmt+0x36e>
  800fb3:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800fb7:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800fbb:	48 89 d6             	mov    %rdx,%rsi
  800fbe:	bf 20 00 00 00       	mov    $0x20,%edi
  800fc3:	ff d0                	callq  *%rax
  800fc5:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  800fc9:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800fcd:	7f e4                	jg     800fb3 <vprintfmt+0x358>
  800fcf:	e9 90 01 00 00       	jmpq   801164 <vprintfmt+0x509>
  800fd4:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  800fd8:	be 03 00 00 00       	mov    $0x3,%esi
  800fdd:	48 89 c7             	mov    %rax,%rdi
  800fe0:	48 b8 4b 0b 80 00 00 	movabs $0x800b4b,%rax
  800fe7:	00 00 00 
  800fea:	ff d0                	callq  *%rax
  800fec:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  800ff0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800ff4:	48 85 c0             	test   %rax,%rax
  800ff7:	79 1d                	jns    801016 <vprintfmt+0x3bb>
  800ff9:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800ffd:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  801001:	48 89 d6             	mov    %rdx,%rsi
  801004:	bf 2d 00 00 00       	mov    $0x2d,%edi
  801009:	ff d0                	callq  *%rax
  80100b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80100f:	48 f7 d8             	neg    %rax
  801012:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  801016:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%rbp)
  80101d:	e9 d5 00 00 00       	jmpq   8010f7 <vprintfmt+0x49c>
  801022:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  801026:	be 03 00 00 00       	mov    $0x3,%esi
  80102b:	48 89 c7             	mov    %rax,%rdi
  80102e:	48 b8 3b 0a 80 00 00 	movabs $0x800a3b,%rax
  801035:	00 00 00 
  801038:	ff d0                	callq  *%rax
  80103a:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  80103e:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%rbp)
  801045:	e9 ad 00 00 00       	jmpq   8010f7 <vprintfmt+0x49c>
  80104a:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  80104e:	be 03 00 00 00       	mov    $0x3,%esi
  801053:	48 89 c7             	mov    %rax,%rdi
  801056:	48 b8 3b 0a 80 00 00 	movabs $0x800a3b,%rax
  80105d:	00 00 00 
  801060:	ff d0                	callq  *%rax
  801062:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  801066:	c7 45 e4 08 00 00 00 	movl   $0x8,-0x1c(%rbp)
  80106d:	e9 85 00 00 00       	jmpq   8010f7 <vprintfmt+0x49c>
  801072:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  801076:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80107a:	48 89 d6             	mov    %rdx,%rsi
  80107d:	bf 30 00 00 00       	mov    $0x30,%edi
  801082:	ff d0                	callq  *%rax
  801084:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  801088:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80108c:	48 89 d6             	mov    %rdx,%rsi
  80108f:	bf 78 00 00 00       	mov    $0x78,%edi
  801094:	ff d0                	callq  *%rax
  801096:	8b 45 b8             	mov    -0x48(%rbp),%eax
  801099:	83 f8 30             	cmp    $0x30,%eax
  80109c:	73 17                	jae    8010b5 <vprintfmt+0x45a>
  80109e:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8010a2:	8b 45 b8             	mov    -0x48(%rbp),%eax
  8010a5:	89 c0                	mov    %eax,%eax
  8010a7:	48 01 d0             	add    %rdx,%rax
  8010aa:	8b 55 b8             	mov    -0x48(%rbp),%edx
  8010ad:	83 c2 08             	add    $0x8,%edx
  8010b0:	89 55 b8             	mov    %edx,-0x48(%rbp)
  8010b3:	eb 0f                	jmp    8010c4 <vprintfmt+0x469>
  8010b5:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  8010b9:	48 89 d0             	mov    %rdx,%rax
  8010bc:	48 83 c2 08          	add    $0x8,%rdx
  8010c0:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  8010c4:	48 8b 00             	mov    (%rax),%rax
  8010c7:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  8010cb:	c7 45 e4 10 00 00 00 	movl   $0x10,-0x1c(%rbp)
  8010d2:	eb 23                	jmp    8010f7 <vprintfmt+0x49c>
  8010d4:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  8010d8:	be 03 00 00 00       	mov    $0x3,%esi
  8010dd:	48 89 c7             	mov    %rax,%rdi
  8010e0:	48 b8 3b 0a 80 00 00 	movabs $0x800a3b,%rax
  8010e7:	00 00 00 
  8010ea:	ff d0                	callq  *%rax
  8010ec:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  8010f0:	c7 45 e4 10 00 00 00 	movl   $0x10,-0x1c(%rbp)
  8010f7:	44 0f be 45 d3       	movsbl -0x2d(%rbp),%r8d
  8010fc:	8b 4d e4             	mov    -0x1c(%rbp),%ecx
  8010ff:	8b 7d dc             	mov    -0x24(%rbp),%edi
  801102:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  801106:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  80110a:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80110e:	45 89 c1             	mov    %r8d,%r9d
  801111:	41 89 f8             	mov    %edi,%r8d
  801114:	48 89 c7             	mov    %rax,%rdi
  801117:	48 b8 80 09 80 00 00 	movabs $0x800980,%rax
  80111e:	00 00 00 
  801121:	ff d0                	callq  *%rax
  801123:	eb 3f                	jmp    801164 <vprintfmt+0x509>
  801125:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  801129:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80112d:	48 89 d6             	mov    %rdx,%rsi
  801130:	89 df                	mov    %ebx,%edi
  801132:	ff d0                	callq  *%rax
  801134:	eb 2e                	jmp    801164 <vprintfmt+0x509>
  801136:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  80113a:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80113e:	48 89 d6             	mov    %rdx,%rsi
  801141:	bf 25 00 00 00       	mov    $0x25,%edi
  801146:	ff d0                	callq  *%rax
  801148:	48 83 6d 98 01       	subq   $0x1,-0x68(%rbp)
  80114d:	eb 05                	jmp    801154 <vprintfmt+0x4f9>
  80114f:	48 83 6d 98 01       	subq   $0x1,-0x68(%rbp)
  801154:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  801158:	48 83 e8 01          	sub    $0x1,%rax
  80115c:	0f b6 00             	movzbl (%rax),%eax
  80115f:	3c 25                	cmp    $0x25,%al
  801161:	75 ec                	jne    80114f <vprintfmt+0x4f4>
  801163:	90                   	nop
  801164:	90                   	nop
  801165:	e9 43 fb ff ff       	jmpq   800cad <vprintfmt+0x52>
  80116a:	48 83 c4 60          	add    $0x60,%rsp
  80116e:	5b                   	pop    %rbx
  80116f:	41 5c                	pop    %r12
  801171:	5d                   	pop    %rbp
  801172:	c3                   	retq   

0000000000801173 <printfmt>:
  801173:	55                   	push   %rbp
  801174:	48 89 e5             	mov    %rsp,%rbp
  801177:	48 81 ec f0 00 00 00 	sub    $0xf0,%rsp
  80117e:	48 89 bd 28 ff ff ff 	mov    %rdi,-0xd8(%rbp)
  801185:	48 89 b5 20 ff ff ff 	mov    %rsi,-0xe0(%rbp)
  80118c:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  801193:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  80119a:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  8011a1:	84 c0                	test   %al,%al
  8011a3:	74 20                	je     8011c5 <printfmt+0x52>
  8011a5:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  8011a9:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  8011ad:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  8011b1:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  8011b5:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  8011b9:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  8011bd:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  8011c1:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  8011c5:	48 89 95 18 ff ff ff 	mov    %rdx,-0xe8(%rbp)
  8011cc:	c7 85 38 ff ff ff 18 	movl   $0x18,-0xc8(%rbp)
  8011d3:	00 00 00 
  8011d6:	c7 85 3c ff ff ff 30 	movl   $0x30,-0xc4(%rbp)
  8011dd:	00 00 00 
  8011e0:	48 8d 45 10          	lea    0x10(%rbp),%rax
  8011e4:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  8011eb:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  8011f2:	48 89 85 48 ff ff ff 	mov    %rax,-0xb8(%rbp)
  8011f9:	48 8d 8d 38 ff ff ff 	lea    -0xc8(%rbp),%rcx
  801200:	48 8b 95 18 ff ff ff 	mov    -0xe8(%rbp),%rdx
  801207:	48 8b b5 20 ff ff ff 	mov    -0xe0(%rbp),%rsi
  80120e:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  801215:	48 89 c7             	mov    %rax,%rdi
  801218:	48 b8 5b 0c 80 00 00 	movabs $0x800c5b,%rax
  80121f:	00 00 00 
  801222:	ff d0                	callq  *%rax
  801224:	c9                   	leaveq 
  801225:	c3                   	retq   

0000000000801226 <sprintputch>:
  801226:	55                   	push   %rbp
  801227:	48 89 e5             	mov    %rsp,%rbp
  80122a:	48 83 ec 10          	sub    $0x10,%rsp
  80122e:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801231:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801235:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801239:	8b 40 10             	mov    0x10(%rax),%eax
  80123c:	8d 50 01             	lea    0x1(%rax),%edx
  80123f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801243:	89 50 10             	mov    %edx,0x10(%rax)
  801246:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80124a:	48 8b 10             	mov    (%rax),%rdx
  80124d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801251:	48 8b 40 08          	mov    0x8(%rax),%rax
  801255:	48 39 c2             	cmp    %rax,%rdx
  801258:	73 17                	jae    801271 <sprintputch+0x4b>
  80125a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80125e:	48 8b 00             	mov    (%rax),%rax
  801261:	48 8d 48 01          	lea    0x1(%rax),%rcx
  801265:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801269:	48 89 0a             	mov    %rcx,(%rdx)
  80126c:	8b 55 fc             	mov    -0x4(%rbp),%edx
  80126f:	88 10                	mov    %dl,(%rax)
  801271:	c9                   	leaveq 
  801272:	c3                   	retq   

0000000000801273 <vsnprintf>:
  801273:	55                   	push   %rbp
  801274:	48 89 e5             	mov    %rsp,%rbp
  801277:	48 83 ec 50          	sub    $0x50,%rsp
  80127b:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  80127f:	89 75 c4             	mov    %esi,-0x3c(%rbp)
  801282:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
  801286:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
  80128a:	48 8d 45 e8          	lea    -0x18(%rbp),%rax
  80128e:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  801292:	48 8b 0a             	mov    (%rdx),%rcx
  801295:	48 89 08             	mov    %rcx,(%rax)
  801298:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  80129c:	48 89 48 08          	mov    %rcx,0x8(%rax)
  8012a0:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  8012a4:	48 89 50 10          	mov    %rdx,0x10(%rax)
  8012a8:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8012ac:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
  8012b0:	8b 45 c4             	mov    -0x3c(%rbp),%eax
  8012b3:	48 98                	cltq   
  8012b5:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  8012b9:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8012bd:	48 01 d0             	add    %rdx,%rax
  8012c0:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
  8012c4:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%rbp)
  8012cb:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  8012d0:	74 06                	je     8012d8 <vsnprintf+0x65>
  8012d2:	83 7d c4 00          	cmpl   $0x0,-0x3c(%rbp)
  8012d6:	7f 07                	jg     8012df <vsnprintf+0x6c>
  8012d8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  8012dd:	eb 2f                	jmp    80130e <vsnprintf+0x9b>
  8012df:	48 8d 4d e8          	lea    -0x18(%rbp),%rcx
  8012e3:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
  8012e7:	48 8d 45 d0          	lea    -0x30(%rbp),%rax
  8012eb:	48 89 c6             	mov    %rax,%rsi
  8012ee:	48 bf 26 12 80 00 00 	movabs $0x801226,%rdi
  8012f5:	00 00 00 
  8012f8:	48 b8 5b 0c 80 00 00 	movabs $0x800c5b,%rax
  8012ff:	00 00 00 
  801302:	ff d0                	callq  *%rax
  801304:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801308:	c6 00 00             	movb   $0x0,(%rax)
  80130b:	8b 45 e0             	mov    -0x20(%rbp),%eax
  80130e:	c9                   	leaveq 
  80130f:	c3                   	retq   

0000000000801310 <snprintf>:
  801310:	55                   	push   %rbp
  801311:	48 89 e5             	mov    %rsp,%rbp
  801314:	48 81 ec 10 01 00 00 	sub    $0x110,%rsp
  80131b:	48 89 bd 08 ff ff ff 	mov    %rdi,-0xf8(%rbp)
  801322:	89 b5 04 ff ff ff    	mov    %esi,-0xfc(%rbp)
  801328:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  80132f:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  801336:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  80133d:	84 c0                	test   %al,%al
  80133f:	74 20                	je     801361 <snprintf+0x51>
  801341:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  801345:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  801349:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  80134d:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  801351:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  801355:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  801359:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  80135d:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  801361:	48 89 95 f8 fe ff ff 	mov    %rdx,-0x108(%rbp)
  801368:	c7 85 30 ff ff ff 18 	movl   $0x18,-0xd0(%rbp)
  80136f:	00 00 00 
  801372:	c7 85 34 ff ff ff 30 	movl   $0x30,-0xcc(%rbp)
  801379:	00 00 00 
  80137c:	48 8d 45 10          	lea    0x10(%rbp),%rax
  801380:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  801387:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  80138e:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  801395:	48 8d 85 18 ff ff ff 	lea    -0xe8(%rbp),%rax
  80139c:	48 8d 95 30 ff ff ff 	lea    -0xd0(%rbp),%rdx
  8013a3:	48 8b 0a             	mov    (%rdx),%rcx
  8013a6:	48 89 08             	mov    %rcx,(%rax)
  8013a9:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  8013ad:	48 89 48 08          	mov    %rcx,0x8(%rax)
  8013b1:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  8013b5:	48 89 50 10          	mov    %rdx,0x10(%rax)
  8013b9:	48 8d 8d 18 ff ff ff 	lea    -0xe8(%rbp),%rcx
  8013c0:	48 8b 95 f8 fe ff ff 	mov    -0x108(%rbp),%rdx
  8013c7:	8b b5 04 ff ff ff    	mov    -0xfc(%rbp),%esi
  8013cd:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  8013d4:	48 89 c7             	mov    %rax,%rdi
  8013d7:	48 b8 73 12 80 00 00 	movabs $0x801273,%rax
  8013de:	00 00 00 
  8013e1:	ff d0                	callq  *%rax
  8013e3:	89 85 4c ff ff ff    	mov    %eax,-0xb4(%rbp)
  8013e9:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
  8013ef:	c9                   	leaveq 
  8013f0:	c3                   	retq   

00000000008013f1 <strlen>:
  8013f1:	55                   	push   %rbp
  8013f2:	48 89 e5             	mov    %rsp,%rbp
  8013f5:	48 83 ec 18          	sub    $0x18,%rsp
  8013f9:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8013fd:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  801404:	eb 09                	jmp    80140f <strlen+0x1e>
  801406:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  80140a:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  80140f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801413:	0f b6 00             	movzbl (%rax),%eax
  801416:	84 c0                	test   %al,%al
  801418:	75 ec                	jne    801406 <strlen+0x15>
  80141a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80141d:	c9                   	leaveq 
  80141e:	c3                   	retq   

000000000080141f <strnlen>:
  80141f:	55                   	push   %rbp
  801420:	48 89 e5             	mov    %rsp,%rbp
  801423:	48 83 ec 20          	sub    $0x20,%rsp
  801427:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80142b:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80142f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  801436:	eb 0e                	jmp    801446 <strnlen+0x27>
  801438:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  80143c:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  801441:	48 83 6d e0 01       	subq   $0x1,-0x20(%rbp)
  801446:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  80144b:	74 0b                	je     801458 <strnlen+0x39>
  80144d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801451:	0f b6 00             	movzbl (%rax),%eax
  801454:	84 c0                	test   %al,%al
  801456:	75 e0                	jne    801438 <strnlen+0x19>
  801458:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80145b:	c9                   	leaveq 
  80145c:	c3                   	retq   

000000000080145d <strcpy>:
  80145d:	55                   	push   %rbp
  80145e:	48 89 e5             	mov    %rsp,%rbp
  801461:	48 83 ec 20          	sub    $0x20,%rsp
  801465:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  801469:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80146d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801471:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  801475:	90                   	nop
  801476:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80147a:	48 8d 50 01          	lea    0x1(%rax),%rdx
  80147e:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  801482:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  801486:	48 8d 4a 01          	lea    0x1(%rdx),%rcx
  80148a:	48 89 4d e0          	mov    %rcx,-0x20(%rbp)
  80148e:	0f b6 12             	movzbl (%rdx),%edx
  801491:	88 10                	mov    %dl,(%rax)
  801493:	0f b6 00             	movzbl (%rax),%eax
  801496:	84 c0                	test   %al,%al
  801498:	75 dc                	jne    801476 <strcpy+0x19>
  80149a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80149e:	c9                   	leaveq 
  80149f:	c3                   	retq   

00000000008014a0 <strcat>:
  8014a0:	55                   	push   %rbp
  8014a1:	48 89 e5             	mov    %rsp,%rbp
  8014a4:	48 83 ec 20          	sub    $0x20,%rsp
  8014a8:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8014ac:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8014b0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8014b4:	48 89 c7             	mov    %rax,%rdi
  8014b7:	48 b8 f1 13 80 00 00 	movabs $0x8013f1,%rax
  8014be:	00 00 00 
  8014c1:	ff d0                	callq  *%rax
  8014c3:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8014c6:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8014c9:	48 63 d0             	movslq %eax,%rdx
  8014cc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8014d0:	48 01 c2             	add    %rax,%rdx
  8014d3:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8014d7:	48 89 c6             	mov    %rax,%rsi
  8014da:	48 89 d7             	mov    %rdx,%rdi
  8014dd:	48 b8 5d 14 80 00 00 	movabs $0x80145d,%rax
  8014e4:	00 00 00 
  8014e7:	ff d0                	callq  *%rax
  8014e9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8014ed:	c9                   	leaveq 
  8014ee:	c3                   	retq   

00000000008014ef <strncpy>:
  8014ef:	55                   	push   %rbp
  8014f0:	48 89 e5             	mov    %rsp,%rbp
  8014f3:	48 83 ec 28          	sub    $0x28,%rsp
  8014f7:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8014fb:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8014ff:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801503:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801507:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  80150b:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  801512:	00 
  801513:	eb 2a                	jmp    80153f <strncpy+0x50>
  801515:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801519:	48 8d 50 01          	lea    0x1(%rax),%rdx
  80151d:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  801521:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  801525:	0f b6 12             	movzbl (%rdx),%edx
  801528:	88 10                	mov    %dl,(%rax)
  80152a:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80152e:	0f b6 00             	movzbl (%rax),%eax
  801531:	84 c0                	test   %al,%al
  801533:	74 05                	je     80153a <strncpy+0x4b>
  801535:	48 83 45 e0 01       	addq   $0x1,-0x20(%rbp)
  80153a:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  80153f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801543:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  801547:	72 cc                	jb     801515 <strncpy+0x26>
  801549:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80154d:	c9                   	leaveq 
  80154e:	c3                   	retq   

000000000080154f <strlcpy>:
  80154f:	55                   	push   %rbp
  801550:	48 89 e5             	mov    %rsp,%rbp
  801553:	48 83 ec 28          	sub    $0x28,%rsp
  801557:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80155b:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80155f:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801563:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801567:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  80156b:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  801570:	74 3d                	je     8015af <strlcpy+0x60>
  801572:	eb 1d                	jmp    801591 <strlcpy+0x42>
  801574:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801578:	48 8d 50 01          	lea    0x1(%rax),%rdx
  80157c:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  801580:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  801584:	48 8d 4a 01          	lea    0x1(%rdx),%rcx
  801588:	48 89 4d e0          	mov    %rcx,-0x20(%rbp)
  80158c:	0f b6 12             	movzbl (%rdx),%edx
  80158f:	88 10                	mov    %dl,(%rax)
  801591:	48 83 6d d8 01       	subq   $0x1,-0x28(%rbp)
  801596:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  80159b:	74 0b                	je     8015a8 <strlcpy+0x59>
  80159d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8015a1:	0f b6 00             	movzbl (%rax),%eax
  8015a4:	84 c0                	test   %al,%al
  8015a6:	75 cc                	jne    801574 <strlcpy+0x25>
  8015a8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8015ac:	c6 00 00             	movb   $0x0,(%rax)
  8015af:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8015b3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8015b7:	48 29 c2             	sub    %rax,%rdx
  8015ba:	48 89 d0             	mov    %rdx,%rax
  8015bd:	c9                   	leaveq 
  8015be:	c3                   	retq   

00000000008015bf <strcmp>:
  8015bf:	55                   	push   %rbp
  8015c0:	48 89 e5             	mov    %rsp,%rbp
  8015c3:	48 83 ec 10          	sub    $0x10,%rsp
  8015c7:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8015cb:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8015cf:	eb 0a                	jmp    8015db <strcmp+0x1c>
  8015d1:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8015d6:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
  8015db:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8015df:	0f b6 00             	movzbl (%rax),%eax
  8015e2:	84 c0                	test   %al,%al
  8015e4:	74 12                	je     8015f8 <strcmp+0x39>
  8015e6:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8015ea:	0f b6 10             	movzbl (%rax),%edx
  8015ed:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8015f1:	0f b6 00             	movzbl (%rax),%eax
  8015f4:	38 c2                	cmp    %al,%dl
  8015f6:	74 d9                	je     8015d1 <strcmp+0x12>
  8015f8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8015fc:	0f b6 00             	movzbl (%rax),%eax
  8015ff:	0f b6 d0             	movzbl %al,%edx
  801602:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801606:	0f b6 00             	movzbl (%rax),%eax
  801609:	0f b6 c0             	movzbl %al,%eax
  80160c:	29 c2                	sub    %eax,%edx
  80160e:	89 d0                	mov    %edx,%eax
  801610:	c9                   	leaveq 
  801611:	c3                   	retq   

0000000000801612 <strncmp>:
  801612:	55                   	push   %rbp
  801613:	48 89 e5             	mov    %rsp,%rbp
  801616:	48 83 ec 18          	sub    $0x18,%rsp
  80161a:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80161e:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801622:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  801626:	eb 0f                	jmp    801637 <strncmp+0x25>
  801628:	48 83 6d e8 01       	subq   $0x1,-0x18(%rbp)
  80162d:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  801632:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
  801637:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  80163c:	74 1d                	je     80165b <strncmp+0x49>
  80163e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801642:	0f b6 00             	movzbl (%rax),%eax
  801645:	84 c0                	test   %al,%al
  801647:	74 12                	je     80165b <strncmp+0x49>
  801649:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80164d:	0f b6 10             	movzbl (%rax),%edx
  801650:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801654:	0f b6 00             	movzbl (%rax),%eax
  801657:	38 c2                	cmp    %al,%dl
  801659:	74 cd                	je     801628 <strncmp+0x16>
  80165b:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  801660:	75 07                	jne    801669 <strncmp+0x57>
  801662:	b8 00 00 00 00       	mov    $0x0,%eax
  801667:	eb 18                	jmp    801681 <strncmp+0x6f>
  801669:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80166d:	0f b6 00             	movzbl (%rax),%eax
  801670:	0f b6 d0             	movzbl %al,%edx
  801673:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801677:	0f b6 00             	movzbl (%rax),%eax
  80167a:	0f b6 c0             	movzbl %al,%eax
  80167d:	29 c2                	sub    %eax,%edx
  80167f:	89 d0                	mov    %edx,%eax
  801681:	c9                   	leaveq 
  801682:	c3                   	retq   

0000000000801683 <strchr>:
  801683:	55                   	push   %rbp
  801684:	48 89 e5             	mov    %rsp,%rbp
  801687:	48 83 ec 0c          	sub    $0xc,%rsp
  80168b:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80168f:	89 f0                	mov    %esi,%eax
  801691:	88 45 f4             	mov    %al,-0xc(%rbp)
  801694:	eb 17                	jmp    8016ad <strchr+0x2a>
  801696:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80169a:	0f b6 00             	movzbl (%rax),%eax
  80169d:	3a 45 f4             	cmp    -0xc(%rbp),%al
  8016a0:	75 06                	jne    8016a8 <strchr+0x25>
  8016a2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8016a6:	eb 15                	jmp    8016bd <strchr+0x3a>
  8016a8:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8016ad:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8016b1:	0f b6 00             	movzbl (%rax),%eax
  8016b4:	84 c0                	test   %al,%al
  8016b6:	75 de                	jne    801696 <strchr+0x13>
  8016b8:	b8 00 00 00 00       	mov    $0x0,%eax
  8016bd:	c9                   	leaveq 
  8016be:	c3                   	retq   

00000000008016bf <strfind>:
  8016bf:	55                   	push   %rbp
  8016c0:	48 89 e5             	mov    %rsp,%rbp
  8016c3:	48 83 ec 0c          	sub    $0xc,%rsp
  8016c7:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8016cb:	89 f0                	mov    %esi,%eax
  8016cd:	88 45 f4             	mov    %al,-0xc(%rbp)
  8016d0:	eb 13                	jmp    8016e5 <strfind+0x26>
  8016d2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8016d6:	0f b6 00             	movzbl (%rax),%eax
  8016d9:	3a 45 f4             	cmp    -0xc(%rbp),%al
  8016dc:	75 02                	jne    8016e0 <strfind+0x21>
  8016de:	eb 10                	jmp    8016f0 <strfind+0x31>
  8016e0:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8016e5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8016e9:	0f b6 00             	movzbl (%rax),%eax
  8016ec:	84 c0                	test   %al,%al
  8016ee:	75 e2                	jne    8016d2 <strfind+0x13>
  8016f0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8016f4:	c9                   	leaveq 
  8016f5:	c3                   	retq   

00000000008016f6 <memset>:
  8016f6:	55                   	push   %rbp
  8016f7:	48 89 e5             	mov    %rsp,%rbp
  8016fa:	48 83 ec 18          	sub    $0x18,%rsp
  8016fe:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801702:	89 75 f4             	mov    %esi,-0xc(%rbp)
  801705:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  801709:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  80170e:	75 06                	jne    801716 <memset+0x20>
  801710:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801714:	eb 69                	jmp    80177f <memset+0x89>
  801716:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80171a:	83 e0 03             	and    $0x3,%eax
  80171d:	48 85 c0             	test   %rax,%rax
  801720:	75 48                	jne    80176a <memset+0x74>
  801722:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801726:	83 e0 03             	and    $0x3,%eax
  801729:	48 85 c0             	test   %rax,%rax
  80172c:	75 3c                	jne    80176a <memset+0x74>
  80172e:	81 65 f4 ff 00 00 00 	andl   $0xff,-0xc(%rbp)
  801735:	8b 45 f4             	mov    -0xc(%rbp),%eax
  801738:	c1 e0 18             	shl    $0x18,%eax
  80173b:	89 c2                	mov    %eax,%edx
  80173d:	8b 45 f4             	mov    -0xc(%rbp),%eax
  801740:	c1 e0 10             	shl    $0x10,%eax
  801743:	09 c2                	or     %eax,%edx
  801745:	8b 45 f4             	mov    -0xc(%rbp),%eax
  801748:	c1 e0 08             	shl    $0x8,%eax
  80174b:	09 d0                	or     %edx,%eax
  80174d:	09 45 f4             	or     %eax,-0xc(%rbp)
  801750:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801754:	48 c1 e8 02          	shr    $0x2,%rax
  801758:	48 89 c1             	mov    %rax,%rcx
  80175b:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80175f:	8b 45 f4             	mov    -0xc(%rbp),%eax
  801762:	48 89 d7             	mov    %rdx,%rdi
  801765:	fc                   	cld    
  801766:	f3 ab                	rep stos %eax,%es:(%rdi)
  801768:	eb 11                	jmp    80177b <memset+0x85>
  80176a:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80176e:	8b 45 f4             	mov    -0xc(%rbp),%eax
  801771:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  801775:	48 89 d7             	mov    %rdx,%rdi
  801778:	fc                   	cld    
  801779:	f3 aa                	rep stos %al,%es:(%rdi)
  80177b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80177f:	c9                   	leaveq 
  801780:	c3                   	retq   

0000000000801781 <memmove>:
  801781:	55                   	push   %rbp
  801782:	48 89 e5             	mov    %rsp,%rbp
  801785:	48 83 ec 28          	sub    $0x28,%rsp
  801789:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80178d:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  801791:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801795:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  801799:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  80179d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8017a1:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  8017a5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8017a9:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
  8017ad:	0f 83 88 00 00 00    	jae    80183b <memmove+0xba>
  8017b3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8017b7:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8017bb:	48 01 d0             	add    %rdx,%rax
  8017be:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
  8017c2:	76 77                	jbe    80183b <memmove+0xba>
  8017c4:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8017c8:	48 01 45 f8          	add    %rax,-0x8(%rbp)
  8017cc:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8017d0:	48 01 45 f0          	add    %rax,-0x10(%rbp)
  8017d4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8017d8:	83 e0 03             	and    $0x3,%eax
  8017db:	48 85 c0             	test   %rax,%rax
  8017de:	75 3b                	jne    80181b <memmove+0x9a>
  8017e0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8017e4:	83 e0 03             	and    $0x3,%eax
  8017e7:	48 85 c0             	test   %rax,%rax
  8017ea:	75 2f                	jne    80181b <memmove+0x9a>
  8017ec:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8017f0:	83 e0 03             	and    $0x3,%eax
  8017f3:	48 85 c0             	test   %rax,%rax
  8017f6:	75 23                	jne    80181b <memmove+0x9a>
  8017f8:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8017fc:	48 83 e8 04          	sub    $0x4,%rax
  801800:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  801804:	48 83 ea 04          	sub    $0x4,%rdx
  801808:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  80180c:	48 c1 e9 02          	shr    $0x2,%rcx
  801810:	48 89 c7             	mov    %rax,%rdi
  801813:	48 89 d6             	mov    %rdx,%rsi
  801816:	fd                   	std    
  801817:	f3 a5                	rep movsl %ds:(%rsi),%es:(%rdi)
  801819:	eb 1d                	jmp    801838 <memmove+0xb7>
  80181b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80181f:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  801823:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801827:	48 8d 70 ff          	lea    -0x1(%rax),%rsi
  80182b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80182f:	48 89 d7             	mov    %rdx,%rdi
  801832:	48 89 c1             	mov    %rax,%rcx
  801835:	fd                   	std    
  801836:	f3 a4                	rep movsb %ds:(%rsi),%es:(%rdi)
  801838:	fc                   	cld    
  801839:	eb 57                	jmp    801892 <memmove+0x111>
  80183b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80183f:	83 e0 03             	and    $0x3,%eax
  801842:	48 85 c0             	test   %rax,%rax
  801845:	75 36                	jne    80187d <memmove+0xfc>
  801847:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80184b:	83 e0 03             	and    $0x3,%eax
  80184e:	48 85 c0             	test   %rax,%rax
  801851:	75 2a                	jne    80187d <memmove+0xfc>
  801853:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801857:	83 e0 03             	and    $0x3,%eax
  80185a:	48 85 c0             	test   %rax,%rax
  80185d:	75 1e                	jne    80187d <memmove+0xfc>
  80185f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801863:	48 c1 e8 02          	shr    $0x2,%rax
  801867:	48 89 c1             	mov    %rax,%rcx
  80186a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80186e:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  801872:	48 89 c7             	mov    %rax,%rdi
  801875:	48 89 d6             	mov    %rdx,%rsi
  801878:	fc                   	cld    
  801879:	f3 a5                	rep movsl %ds:(%rsi),%es:(%rdi)
  80187b:	eb 15                	jmp    801892 <memmove+0x111>
  80187d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801881:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  801885:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  801889:	48 89 c7             	mov    %rax,%rdi
  80188c:	48 89 d6             	mov    %rdx,%rsi
  80188f:	fc                   	cld    
  801890:	f3 a4                	rep movsb %ds:(%rsi),%es:(%rdi)
  801892:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801896:	c9                   	leaveq 
  801897:	c3                   	retq   

0000000000801898 <memcpy>:
  801898:	55                   	push   %rbp
  801899:	48 89 e5             	mov    %rsp,%rbp
  80189c:	48 83 ec 18          	sub    $0x18,%rsp
  8018a0:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8018a4:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8018a8:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8018ac:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8018b0:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
  8018b4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8018b8:	48 89 ce             	mov    %rcx,%rsi
  8018bb:	48 89 c7             	mov    %rax,%rdi
  8018be:	48 b8 81 17 80 00 00 	movabs $0x801781,%rax
  8018c5:	00 00 00 
  8018c8:	ff d0                	callq  *%rax
  8018ca:	c9                   	leaveq 
  8018cb:	c3                   	retq   

00000000008018cc <memcmp>:
  8018cc:	55                   	push   %rbp
  8018cd:	48 89 e5             	mov    %rsp,%rbp
  8018d0:	48 83 ec 28          	sub    $0x28,%rsp
  8018d4:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8018d8:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8018dc:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8018e0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8018e4:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8018e8:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8018ec:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  8018f0:	eb 36                	jmp    801928 <memcmp+0x5c>
  8018f2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8018f6:	0f b6 10             	movzbl (%rax),%edx
  8018f9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8018fd:	0f b6 00             	movzbl (%rax),%eax
  801900:	38 c2                	cmp    %al,%dl
  801902:	74 1a                	je     80191e <memcmp+0x52>
  801904:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801908:	0f b6 00             	movzbl (%rax),%eax
  80190b:	0f b6 d0             	movzbl %al,%edx
  80190e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801912:	0f b6 00             	movzbl (%rax),%eax
  801915:	0f b6 c0             	movzbl %al,%eax
  801918:	29 c2                	sub    %eax,%edx
  80191a:	89 d0                	mov    %edx,%eax
  80191c:	eb 20                	jmp    80193e <memcmp+0x72>
  80191e:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  801923:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
  801928:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80192c:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  801930:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801934:	48 85 c0             	test   %rax,%rax
  801937:	75 b9                	jne    8018f2 <memcmp+0x26>
  801939:	b8 00 00 00 00       	mov    $0x0,%eax
  80193e:	c9                   	leaveq 
  80193f:	c3                   	retq   

0000000000801940 <memfind>:
  801940:	55                   	push   %rbp
  801941:	48 89 e5             	mov    %rsp,%rbp
  801944:	48 83 ec 28          	sub    $0x28,%rsp
  801948:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80194c:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  80194f:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801953:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801957:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80195b:	48 01 d0             	add    %rdx,%rax
  80195e:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  801962:	eb 15                	jmp    801979 <memfind+0x39>
  801964:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801968:	0f b6 10             	movzbl (%rax),%edx
  80196b:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  80196e:	38 c2                	cmp    %al,%dl
  801970:	75 02                	jne    801974 <memfind+0x34>
  801972:	eb 0f                	jmp    801983 <memfind+0x43>
  801974:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  801979:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80197d:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
  801981:	72 e1                	jb     801964 <memfind+0x24>
  801983:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801987:	c9                   	leaveq 
  801988:	c3                   	retq   

0000000000801989 <strtol>:
  801989:	55                   	push   %rbp
  80198a:	48 89 e5             	mov    %rsp,%rbp
  80198d:	48 83 ec 34          	sub    $0x34,%rsp
  801991:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  801995:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  801999:	89 55 cc             	mov    %edx,-0x34(%rbp)
  80199c:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8019a3:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
  8019aa:	00 
  8019ab:	eb 05                	jmp    8019b2 <strtol+0x29>
  8019ad:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  8019b2:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8019b6:	0f b6 00             	movzbl (%rax),%eax
  8019b9:	3c 20                	cmp    $0x20,%al
  8019bb:	74 f0                	je     8019ad <strtol+0x24>
  8019bd:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8019c1:	0f b6 00             	movzbl (%rax),%eax
  8019c4:	3c 09                	cmp    $0x9,%al
  8019c6:	74 e5                	je     8019ad <strtol+0x24>
  8019c8:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8019cc:	0f b6 00             	movzbl (%rax),%eax
  8019cf:	3c 2b                	cmp    $0x2b,%al
  8019d1:	75 07                	jne    8019da <strtol+0x51>
  8019d3:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  8019d8:	eb 17                	jmp    8019f1 <strtol+0x68>
  8019da:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8019de:	0f b6 00             	movzbl (%rax),%eax
  8019e1:	3c 2d                	cmp    $0x2d,%al
  8019e3:	75 0c                	jne    8019f1 <strtol+0x68>
  8019e5:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  8019ea:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%rbp)
  8019f1:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  8019f5:	74 06                	je     8019fd <strtol+0x74>
  8019f7:	83 7d cc 10          	cmpl   $0x10,-0x34(%rbp)
  8019fb:	75 28                	jne    801a25 <strtol+0x9c>
  8019fd:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a01:	0f b6 00             	movzbl (%rax),%eax
  801a04:	3c 30                	cmp    $0x30,%al
  801a06:	75 1d                	jne    801a25 <strtol+0x9c>
  801a08:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a0c:	48 83 c0 01          	add    $0x1,%rax
  801a10:	0f b6 00             	movzbl (%rax),%eax
  801a13:	3c 78                	cmp    $0x78,%al
  801a15:	75 0e                	jne    801a25 <strtol+0x9c>
  801a17:	48 83 45 d8 02       	addq   $0x2,-0x28(%rbp)
  801a1c:	c7 45 cc 10 00 00 00 	movl   $0x10,-0x34(%rbp)
  801a23:	eb 2c                	jmp    801a51 <strtol+0xc8>
  801a25:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  801a29:	75 19                	jne    801a44 <strtol+0xbb>
  801a2b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a2f:	0f b6 00             	movzbl (%rax),%eax
  801a32:	3c 30                	cmp    $0x30,%al
  801a34:	75 0e                	jne    801a44 <strtol+0xbb>
  801a36:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  801a3b:	c7 45 cc 08 00 00 00 	movl   $0x8,-0x34(%rbp)
  801a42:	eb 0d                	jmp    801a51 <strtol+0xc8>
  801a44:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  801a48:	75 07                	jne    801a51 <strtol+0xc8>
  801a4a:	c7 45 cc 0a 00 00 00 	movl   $0xa,-0x34(%rbp)
  801a51:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a55:	0f b6 00             	movzbl (%rax),%eax
  801a58:	3c 2f                	cmp    $0x2f,%al
  801a5a:	7e 1d                	jle    801a79 <strtol+0xf0>
  801a5c:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a60:	0f b6 00             	movzbl (%rax),%eax
  801a63:	3c 39                	cmp    $0x39,%al
  801a65:	7f 12                	jg     801a79 <strtol+0xf0>
  801a67:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a6b:	0f b6 00             	movzbl (%rax),%eax
  801a6e:	0f be c0             	movsbl %al,%eax
  801a71:	83 e8 30             	sub    $0x30,%eax
  801a74:	89 45 ec             	mov    %eax,-0x14(%rbp)
  801a77:	eb 4e                	jmp    801ac7 <strtol+0x13e>
  801a79:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a7d:	0f b6 00             	movzbl (%rax),%eax
  801a80:	3c 60                	cmp    $0x60,%al
  801a82:	7e 1d                	jle    801aa1 <strtol+0x118>
  801a84:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a88:	0f b6 00             	movzbl (%rax),%eax
  801a8b:	3c 7a                	cmp    $0x7a,%al
  801a8d:	7f 12                	jg     801aa1 <strtol+0x118>
  801a8f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a93:	0f b6 00             	movzbl (%rax),%eax
  801a96:	0f be c0             	movsbl %al,%eax
  801a99:	83 e8 57             	sub    $0x57,%eax
  801a9c:	89 45 ec             	mov    %eax,-0x14(%rbp)
  801a9f:	eb 26                	jmp    801ac7 <strtol+0x13e>
  801aa1:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801aa5:	0f b6 00             	movzbl (%rax),%eax
  801aa8:	3c 40                	cmp    $0x40,%al
  801aaa:	7e 48                	jle    801af4 <strtol+0x16b>
  801aac:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801ab0:	0f b6 00             	movzbl (%rax),%eax
  801ab3:	3c 5a                	cmp    $0x5a,%al
  801ab5:	7f 3d                	jg     801af4 <strtol+0x16b>
  801ab7:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801abb:	0f b6 00             	movzbl (%rax),%eax
  801abe:	0f be c0             	movsbl %al,%eax
  801ac1:	83 e8 37             	sub    $0x37,%eax
  801ac4:	89 45 ec             	mov    %eax,-0x14(%rbp)
  801ac7:	8b 45 ec             	mov    -0x14(%rbp),%eax
  801aca:	3b 45 cc             	cmp    -0x34(%rbp),%eax
  801acd:	7c 02                	jl     801ad1 <strtol+0x148>
  801acf:	eb 23                	jmp    801af4 <strtol+0x16b>
  801ad1:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  801ad6:	8b 45 cc             	mov    -0x34(%rbp),%eax
  801ad9:	48 98                	cltq   
  801adb:	48 0f af 45 f0       	imul   -0x10(%rbp),%rax
  801ae0:	48 89 c2             	mov    %rax,%rdx
  801ae3:	8b 45 ec             	mov    -0x14(%rbp),%eax
  801ae6:	48 98                	cltq   
  801ae8:	48 01 d0             	add    %rdx,%rax
  801aeb:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  801aef:	e9 5d ff ff ff       	jmpq   801a51 <strtol+0xc8>
  801af4:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  801af9:	74 0b                	je     801b06 <strtol+0x17d>
  801afb:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801aff:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  801b03:	48 89 10             	mov    %rdx,(%rax)
  801b06:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  801b0a:	74 09                	je     801b15 <strtol+0x18c>
  801b0c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801b10:	48 f7 d8             	neg    %rax
  801b13:	eb 04                	jmp    801b19 <strtol+0x190>
  801b15:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801b19:	c9                   	leaveq 
  801b1a:	c3                   	retq   

0000000000801b1b <strstr>:
  801b1b:	55                   	push   %rbp
  801b1c:	48 89 e5             	mov    %rsp,%rbp
  801b1f:	48 83 ec 30          	sub    $0x30,%rsp
  801b23:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  801b27:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  801b2b:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801b2f:	48 8d 50 01          	lea    0x1(%rax),%rdx
  801b33:	48 89 55 d0          	mov    %rdx,-0x30(%rbp)
  801b37:	0f b6 00             	movzbl (%rax),%eax
  801b3a:	88 45 ff             	mov    %al,-0x1(%rbp)
  801b3d:	80 7d ff 00          	cmpb   $0x0,-0x1(%rbp)
  801b41:	75 06                	jne    801b49 <strstr+0x2e>
  801b43:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b47:	eb 6b                	jmp    801bb4 <strstr+0x99>
  801b49:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801b4d:	48 89 c7             	mov    %rax,%rdi
  801b50:	48 b8 f1 13 80 00 00 	movabs $0x8013f1,%rax
  801b57:	00 00 00 
  801b5a:	ff d0                	callq  *%rax
  801b5c:	48 98                	cltq   
  801b5e:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  801b62:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b66:	48 8d 50 01          	lea    0x1(%rax),%rdx
  801b6a:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801b6e:	0f b6 00             	movzbl (%rax),%eax
  801b71:	88 45 ef             	mov    %al,-0x11(%rbp)
  801b74:	80 7d ef 00          	cmpb   $0x0,-0x11(%rbp)
  801b78:	75 07                	jne    801b81 <strstr+0x66>
  801b7a:	b8 00 00 00 00       	mov    $0x0,%eax
  801b7f:	eb 33                	jmp    801bb4 <strstr+0x99>
  801b81:	0f b6 45 ef          	movzbl -0x11(%rbp),%eax
  801b85:	3a 45 ff             	cmp    -0x1(%rbp),%al
  801b88:	75 d8                	jne    801b62 <strstr+0x47>
  801b8a:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801b8e:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  801b92:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b96:	48 89 ce             	mov    %rcx,%rsi
  801b99:	48 89 c7             	mov    %rax,%rdi
  801b9c:	48 b8 12 16 80 00 00 	movabs $0x801612,%rax
  801ba3:	00 00 00 
  801ba6:	ff d0                	callq  *%rax
  801ba8:	85 c0                	test   %eax,%eax
  801baa:	75 b6                	jne    801b62 <strstr+0x47>
  801bac:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801bb0:	48 83 e8 01          	sub    $0x1,%rax
  801bb4:	c9                   	leaveq 
  801bb5:	c3                   	retq   

0000000000801bb6 <syscall>:
  801bb6:	55                   	push   %rbp
  801bb7:	48 89 e5             	mov    %rsp,%rbp
  801bba:	53                   	push   %rbx
  801bbb:	48 83 ec 48          	sub    $0x48,%rsp
  801bbf:	89 7d dc             	mov    %edi,-0x24(%rbp)
  801bc2:	89 75 d8             	mov    %esi,-0x28(%rbp)
  801bc5:	48 89 55 d0          	mov    %rdx,-0x30(%rbp)
  801bc9:	48 89 4d c8          	mov    %rcx,-0x38(%rbp)
  801bcd:	4c 89 45 c0          	mov    %r8,-0x40(%rbp)
  801bd1:	4c 89 4d b8          	mov    %r9,-0x48(%rbp)
  801bd5:	8b 45 dc             	mov    -0x24(%rbp),%eax
  801bd8:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  801bdc:	48 8b 4d c8          	mov    -0x38(%rbp),%rcx
  801be0:	4c 8b 45 c0          	mov    -0x40(%rbp),%r8
  801be4:	48 8b 7d b8          	mov    -0x48(%rbp),%rdi
  801be8:	48 8b 75 10          	mov    0x10(%rbp),%rsi
  801bec:	4c 89 c3             	mov    %r8,%rbx
  801bef:	cd 30                	int    $0x30
  801bf1:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  801bf5:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  801bf9:	74 3e                	je     801c39 <syscall+0x83>
  801bfb:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  801c00:	7e 37                	jle    801c39 <syscall+0x83>
  801c02:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  801c06:	8b 45 dc             	mov    -0x24(%rbp),%eax
  801c09:	49 89 d0             	mov    %rdx,%r8
  801c0c:	89 c1                	mov    %eax,%ecx
  801c0e:	48 ba c8 4d 80 00 00 	movabs $0x804dc8,%rdx
  801c15:	00 00 00 
  801c18:	be 24 00 00 00       	mov    $0x24,%esi
  801c1d:	48 bf e5 4d 80 00 00 	movabs $0x804de5,%rdi
  801c24:	00 00 00 
  801c27:	b8 00 00 00 00       	mov    $0x0,%eax
  801c2c:	49 b9 b2 43 80 00 00 	movabs $0x8043b2,%r9
  801c33:	00 00 00 
  801c36:	41 ff d1             	callq  *%r9
  801c39:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801c3d:	48 83 c4 48          	add    $0x48,%rsp
  801c41:	5b                   	pop    %rbx
  801c42:	5d                   	pop    %rbp
  801c43:	c3                   	retq   

0000000000801c44 <sys_cputs>:
  801c44:	55                   	push   %rbp
  801c45:	48 89 e5             	mov    %rsp,%rbp
  801c48:	48 83 ec 20          	sub    $0x20,%rsp
  801c4c:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801c50:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801c54:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801c58:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801c5c:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801c63:	00 
  801c64:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801c6a:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801c70:	48 89 d1             	mov    %rdx,%rcx
  801c73:	48 89 c2             	mov    %rax,%rdx
  801c76:	be 00 00 00 00       	mov    $0x0,%esi
  801c7b:	bf 00 00 00 00       	mov    $0x0,%edi
  801c80:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  801c87:	00 00 00 
  801c8a:	ff d0                	callq  *%rax
  801c8c:	c9                   	leaveq 
  801c8d:	c3                   	retq   

0000000000801c8e <sys_cgetc>:
  801c8e:	55                   	push   %rbp
  801c8f:	48 89 e5             	mov    %rsp,%rbp
  801c92:	48 83 ec 10          	sub    $0x10,%rsp
  801c96:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801c9d:	00 
  801c9e:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801ca4:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801caa:	b9 00 00 00 00       	mov    $0x0,%ecx
  801caf:	ba 00 00 00 00       	mov    $0x0,%edx
  801cb4:	be 00 00 00 00       	mov    $0x0,%esi
  801cb9:	bf 01 00 00 00       	mov    $0x1,%edi
  801cbe:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  801cc5:	00 00 00 
  801cc8:	ff d0                	callq  *%rax
  801cca:	c9                   	leaveq 
  801ccb:	c3                   	retq   

0000000000801ccc <sys_env_destroy>:
  801ccc:	55                   	push   %rbp
  801ccd:	48 89 e5             	mov    %rsp,%rbp
  801cd0:	48 83 ec 10          	sub    $0x10,%rsp
  801cd4:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801cd7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801cda:	48 98                	cltq   
  801cdc:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801ce3:	00 
  801ce4:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801cea:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801cf0:	b9 00 00 00 00       	mov    $0x0,%ecx
  801cf5:	48 89 c2             	mov    %rax,%rdx
  801cf8:	be 01 00 00 00       	mov    $0x1,%esi
  801cfd:	bf 03 00 00 00       	mov    $0x3,%edi
  801d02:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  801d09:	00 00 00 
  801d0c:	ff d0                	callq  *%rax
  801d0e:	c9                   	leaveq 
  801d0f:	c3                   	retq   

0000000000801d10 <sys_getenvid>:
  801d10:	55                   	push   %rbp
  801d11:	48 89 e5             	mov    %rsp,%rbp
  801d14:	48 83 ec 10          	sub    $0x10,%rsp
  801d18:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801d1f:	00 
  801d20:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801d26:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801d2c:	b9 00 00 00 00       	mov    $0x0,%ecx
  801d31:	ba 00 00 00 00       	mov    $0x0,%edx
  801d36:	be 00 00 00 00       	mov    $0x0,%esi
  801d3b:	bf 02 00 00 00       	mov    $0x2,%edi
  801d40:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  801d47:	00 00 00 
  801d4a:	ff d0                	callq  *%rax
  801d4c:	c9                   	leaveq 
  801d4d:	c3                   	retq   

0000000000801d4e <sys_yield>:
  801d4e:	55                   	push   %rbp
  801d4f:	48 89 e5             	mov    %rsp,%rbp
  801d52:	48 83 ec 10          	sub    $0x10,%rsp
  801d56:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801d5d:	00 
  801d5e:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801d64:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801d6a:	b9 00 00 00 00       	mov    $0x0,%ecx
  801d6f:	ba 00 00 00 00       	mov    $0x0,%edx
  801d74:	be 00 00 00 00       	mov    $0x0,%esi
  801d79:	bf 0b 00 00 00       	mov    $0xb,%edi
  801d7e:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  801d85:	00 00 00 
  801d88:	ff d0                	callq  *%rax
  801d8a:	c9                   	leaveq 
  801d8b:	c3                   	retq   

0000000000801d8c <sys_page_alloc>:
  801d8c:	55                   	push   %rbp
  801d8d:	48 89 e5             	mov    %rsp,%rbp
  801d90:	48 83 ec 20          	sub    $0x20,%rsp
  801d94:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801d97:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801d9b:	89 55 f8             	mov    %edx,-0x8(%rbp)
  801d9e:	8b 45 f8             	mov    -0x8(%rbp),%eax
  801da1:	48 63 c8             	movslq %eax,%rcx
  801da4:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801da8:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801dab:	48 98                	cltq   
  801dad:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801db4:	00 
  801db5:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801dbb:	49 89 c8             	mov    %rcx,%r8
  801dbe:	48 89 d1             	mov    %rdx,%rcx
  801dc1:	48 89 c2             	mov    %rax,%rdx
  801dc4:	be 01 00 00 00       	mov    $0x1,%esi
  801dc9:	bf 04 00 00 00       	mov    $0x4,%edi
  801dce:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  801dd5:	00 00 00 
  801dd8:	ff d0                	callq  *%rax
  801dda:	c9                   	leaveq 
  801ddb:	c3                   	retq   

0000000000801ddc <sys_page_map>:
  801ddc:	55                   	push   %rbp
  801ddd:	48 89 e5             	mov    %rsp,%rbp
  801de0:	48 83 ec 30          	sub    $0x30,%rsp
  801de4:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801de7:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801deb:	89 55 f8             	mov    %edx,-0x8(%rbp)
  801dee:	48 89 4d e8          	mov    %rcx,-0x18(%rbp)
  801df2:	44 89 45 e4          	mov    %r8d,-0x1c(%rbp)
  801df6:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  801df9:	48 63 c8             	movslq %eax,%rcx
  801dfc:	48 8b 7d e8          	mov    -0x18(%rbp),%rdi
  801e00:	8b 45 f8             	mov    -0x8(%rbp),%eax
  801e03:	48 63 f0             	movslq %eax,%rsi
  801e06:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801e0a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801e0d:	48 98                	cltq   
  801e0f:	48 89 0c 24          	mov    %rcx,(%rsp)
  801e13:	49 89 f9             	mov    %rdi,%r9
  801e16:	49 89 f0             	mov    %rsi,%r8
  801e19:	48 89 d1             	mov    %rdx,%rcx
  801e1c:	48 89 c2             	mov    %rax,%rdx
  801e1f:	be 01 00 00 00       	mov    $0x1,%esi
  801e24:	bf 05 00 00 00       	mov    $0x5,%edi
  801e29:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  801e30:	00 00 00 
  801e33:	ff d0                	callq  *%rax
  801e35:	c9                   	leaveq 
  801e36:	c3                   	retq   

0000000000801e37 <sys_page_unmap>:
  801e37:	55                   	push   %rbp
  801e38:	48 89 e5             	mov    %rsp,%rbp
  801e3b:	48 83 ec 20          	sub    $0x20,%rsp
  801e3f:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801e42:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801e46:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801e4a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801e4d:	48 98                	cltq   
  801e4f:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801e56:	00 
  801e57:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801e5d:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801e63:	48 89 d1             	mov    %rdx,%rcx
  801e66:	48 89 c2             	mov    %rax,%rdx
  801e69:	be 01 00 00 00       	mov    $0x1,%esi
  801e6e:	bf 06 00 00 00       	mov    $0x6,%edi
  801e73:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  801e7a:	00 00 00 
  801e7d:	ff d0                	callq  *%rax
  801e7f:	c9                   	leaveq 
  801e80:	c3                   	retq   

0000000000801e81 <sys_env_set_status>:
  801e81:	55                   	push   %rbp
  801e82:	48 89 e5             	mov    %rsp,%rbp
  801e85:	48 83 ec 10          	sub    $0x10,%rsp
  801e89:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801e8c:	89 75 f8             	mov    %esi,-0x8(%rbp)
  801e8f:	8b 45 f8             	mov    -0x8(%rbp),%eax
  801e92:	48 63 d0             	movslq %eax,%rdx
  801e95:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801e98:	48 98                	cltq   
  801e9a:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801ea1:	00 
  801ea2:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801ea8:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801eae:	48 89 d1             	mov    %rdx,%rcx
  801eb1:	48 89 c2             	mov    %rax,%rdx
  801eb4:	be 01 00 00 00       	mov    $0x1,%esi
  801eb9:	bf 08 00 00 00       	mov    $0x8,%edi
  801ebe:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  801ec5:	00 00 00 
  801ec8:	ff d0                	callq  *%rax
  801eca:	c9                   	leaveq 
  801ecb:	c3                   	retq   

0000000000801ecc <sys_env_set_trapframe>:
  801ecc:	55                   	push   %rbp
  801ecd:	48 89 e5             	mov    %rsp,%rbp
  801ed0:	48 83 ec 20          	sub    $0x20,%rsp
  801ed4:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801ed7:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801edb:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801edf:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801ee2:	48 98                	cltq   
  801ee4:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801eeb:	00 
  801eec:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801ef2:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801ef8:	48 89 d1             	mov    %rdx,%rcx
  801efb:	48 89 c2             	mov    %rax,%rdx
  801efe:	be 01 00 00 00       	mov    $0x1,%esi
  801f03:	bf 09 00 00 00       	mov    $0x9,%edi
  801f08:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  801f0f:	00 00 00 
  801f12:	ff d0                	callq  *%rax
  801f14:	c9                   	leaveq 
  801f15:	c3                   	retq   

0000000000801f16 <sys_env_set_pgfault_upcall>:
  801f16:	55                   	push   %rbp
  801f17:	48 89 e5             	mov    %rsp,%rbp
  801f1a:	48 83 ec 20          	sub    $0x20,%rsp
  801f1e:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801f21:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801f25:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801f29:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801f2c:	48 98                	cltq   
  801f2e:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801f35:	00 
  801f36:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801f3c:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801f42:	48 89 d1             	mov    %rdx,%rcx
  801f45:	48 89 c2             	mov    %rax,%rdx
  801f48:	be 01 00 00 00       	mov    $0x1,%esi
  801f4d:	bf 0a 00 00 00       	mov    $0xa,%edi
  801f52:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  801f59:	00 00 00 
  801f5c:	ff d0                	callq  *%rax
  801f5e:	c9                   	leaveq 
  801f5f:	c3                   	retq   

0000000000801f60 <sys_ipc_try_send>:
  801f60:	55                   	push   %rbp
  801f61:	48 89 e5             	mov    %rsp,%rbp
  801f64:	48 83 ec 20          	sub    $0x20,%rsp
  801f68:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801f6b:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801f6f:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  801f73:	89 4d f8             	mov    %ecx,-0x8(%rbp)
  801f76:	8b 45 f8             	mov    -0x8(%rbp),%eax
  801f79:	48 63 f0             	movslq %eax,%rsi
  801f7c:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  801f80:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801f83:	48 98                	cltq   
  801f85:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801f89:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801f90:	00 
  801f91:	49 89 f1             	mov    %rsi,%r9
  801f94:	49 89 c8             	mov    %rcx,%r8
  801f97:	48 89 d1             	mov    %rdx,%rcx
  801f9a:	48 89 c2             	mov    %rax,%rdx
  801f9d:	be 00 00 00 00       	mov    $0x0,%esi
  801fa2:	bf 0c 00 00 00       	mov    $0xc,%edi
  801fa7:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  801fae:	00 00 00 
  801fb1:	ff d0                	callq  *%rax
  801fb3:	c9                   	leaveq 
  801fb4:	c3                   	retq   

0000000000801fb5 <sys_ipc_recv>:
  801fb5:	55                   	push   %rbp
  801fb6:	48 89 e5             	mov    %rsp,%rbp
  801fb9:	48 83 ec 10          	sub    $0x10,%rsp
  801fbd:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801fc1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801fc5:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801fcc:	00 
  801fcd:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801fd3:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801fd9:	b9 00 00 00 00       	mov    $0x0,%ecx
  801fde:	48 89 c2             	mov    %rax,%rdx
  801fe1:	be 01 00 00 00       	mov    $0x1,%esi
  801fe6:	bf 0d 00 00 00       	mov    $0xd,%edi
  801feb:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  801ff2:	00 00 00 
  801ff5:	ff d0                	callq  *%rax
  801ff7:	c9                   	leaveq 
  801ff8:	c3                   	retq   

0000000000801ff9 <sys_time_msec>:
  801ff9:	55                   	push   %rbp
  801ffa:	48 89 e5             	mov    %rsp,%rbp
  801ffd:	48 83 ec 10          	sub    $0x10,%rsp
  802001:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  802008:	00 
  802009:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  80200f:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  802015:	b9 00 00 00 00       	mov    $0x0,%ecx
  80201a:	ba 00 00 00 00       	mov    $0x0,%edx
  80201f:	be 00 00 00 00       	mov    $0x0,%esi
  802024:	bf 0e 00 00 00       	mov    $0xe,%edi
  802029:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  802030:	00 00 00 
  802033:	ff d0                	callq  *%rax
  802035:	c9                   	leaveq 
  802036:	c3                   	retq   

0000000000802037 <sys_net_transmit>:
  802037:	55                   	push   %rbp
  802038:	48 89 e5             	mov    %rsp,%rbp
  80203b:	48 83 ec 20          	sub    $0x20,%rsp
  80203f:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802043:	89 75 f4             	mov    %esi,-0xc(%rbp)
  802046:	8b 55 f4             	mov    -0xc(%rbp),%edx
  802049:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80204d:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  802054:	00 
  802055:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  80205b:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  802061:	48 89 d1             	mov    %rdx,%rcx
  802064:	48 89 c2             	mov    %rax,%rdx
  802067:	be 00 00 00 00       	mov    $0x0,%esi
  80206c:	bf 0f 00 00 00       	mov    $0xf,%edi
  802071:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  802078:	00 00 00 
  80207b:	ff d0                	callq  *%rax
  80207d:	c9                   	leaveq 
  80207e:	c3                   	retq   

000000000080207f <sys_net_receive>:
  80207f:	55                   	push   %rbp
  802080:	48 89 e5             	mov    %rsp,%rbp
  802083:	48 83 ec 20          	sub    $0x20,%rsp
  802087:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80208b:	89 75 f4             	mov    %esi,-0xc(%rbp)
  80208e:	8b 55 f4             	mov    -0xc(%rbp),%edx
  802091:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802095:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  80209c:	00 
  80209d:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8020a3:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  8020a9:	48 89 d1             	mov    %rdx,%rcx
  8020ac:	48 89 c2             	mov    %rax,%rdx
  8020af:	be 00 00 00 00       	mov    $0x0,%esi
  8020b4:	bf 10 00 00 00       	mov    $0x10,%edi
  8020b9:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  8020c0:	00 00 00 
  8020c3:	ff d0                	callq  *%rax
  8020c5:	c9                   	leaveq 
  8020c6:	c3                   	retq   

00000000008020c7 <sys_ept_map>:
  8020c7:	55                   	push   %rbp
  8020c8:	48 89 e5             	mov    %rsp,%rbp
  8020cb:	48 83 ec 30          	sub    $0x30,%rsp
  8020cf:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8020d2:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8020d6:	89 55 f8             	mov    %edx,-0x8(%rbp)
  8020d9:	48 89 4d e8          	mov    %rcx,-0x18(%rbp)
  8020dd:	44 89 45 e4          	mov    %r8d,-0x1c(%rbp)
  8020e1:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  8020e4:	48 63 c8             	movslq %eax,%rcx
  8020e7:	48 8b 7d e8          	mov    -0x18(%rbp),%rdi
  8020eb:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8020ee:	48 63 f0             	movslq %eax,%rsi
  8020f1:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8020f5:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8020f8:	48 98                	cltq   
  8020fa:	48 89 0c 24          	mov    %rcx,(%rsp)
  8020fe:	49 89 f9             	mov    %rdi,%r9
  802101:	49 89 f0             	mov    %rsi,%r8
  802104:	48 89 d1             	mov    %rdx,%rcx
  802107:	48 89 c2             	mov    %rax,%rdx
  80210a:	be 00 00 00 00       	mov    $0x0,%esi
  80210f:	bf 11 00 00 00       	mov    $0x11,%edi
  802114:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  80211b:	00 00 00 
  80211e:	ff d0                	callq  *%rax
  802120:	c9                   	leaveq 
  802121:	c3                   	retq   

0000000000802122 <sys_env_mkguest>:
  802122:	55                   	push   %rbp
  802123:	48 89 e5             	mov    %rsp,%rbp
  802126:	48 83 ec 20          	sub    $0x20,%rsp
  80212a:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80212e:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  802132:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  802136:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80213a:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  802141:	00 
  802142:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  802148:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  80214e:	48 89 d1             	mov    %rdx,%rcx
  802151:	48 89 c2             	mov    %rax,%rdx
  802154:	be 00 00 00 00       	mov    $0x0,%esi
  802159:	bf 12 00 00 00       	mov    $0x12,%edi
  80215e:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  802165:	00 00 00 
  802168:	ff d0                	callq  *%rax
  80216a:	c9                   	leaveq 
  80216b:	c3                   	retq   

000000000080216c <sys_vmx_list_vms>:
  80216c:	55                   	push   %rbp
  80216d:	48 89 e5             	mov    %rsp,%rbp
  802170:	48 83 ec 10          	sub    $0x10,%rsp
  802174:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  80217b:	00 
  80217c:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  802182:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  802188:	b9 00 00 00 00       	mov    $0x0,%ecx
  80218d:	ba 00 00 00 00       	mov    $0x0,%edx
  802192:	be 00 00 00 00       	mov    $0x0,%esi
  802197:	bf 13 00 00 00       	mov    $0x13,%edi
  80219c:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  8021a3:	00 00 00 
  8021a6:	ff d0                	callq  *%rax
  8021a8:	c9                   	leaveq 
  8021a9:	c3                   	retq   

00000000008021aa <sys_vmx_sel_resume>:
  8021aa:	55                   	push   %rbp
  8021ab:	48 89 e5             	mov    %rsp,%rbp
  8021ae:	48 83 ec 10          	sub    $0x10,%rsp
  8021b2:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8021b5:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8021b8:	48 98                	cltq   
  8021ba:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  8021c1:	00 
  8021c2:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8021c8:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  8021ce:	b9 00 00 00 00       	mov    $0x0,%ecx
  8021d3:	48 89 c2             	mov    %rax,%rdx
  8021d6:	be 00 00 00 00       	mov    $0x0,%esi
  8021db:	bf 14 00 00 00       	mov    $0x14,%edi
  8021e0:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  8021e7:	00 00 00 
  8021ea:	ff d0                	callq  *%rax
  8021ec:	c9                   	leaveq 
  8021ed:	c3                   	retq   

00000000008021ee <sys_vmx_get_vmdisk_number>:
  8021ee:	55                   	push   %rbp
  8021ef:	48 89 e5             	mov    %rsp,%rbp
  8021f2:	48 83 ec 10          	sub    $0x10,%rsp
  8021f6:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  8021fd:	00 
  8021fe:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  802204:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  80220a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80220f:	ba 00 00 00 00       	mov    $0x0,%edx
  802214:	be 00 00 00 00       	mov    $0x0,%esi
  802219:	bf 15 00 00 00       	mov    $0x15,%edi
  80221e:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  802225:	00 00 00 
  802228:	ff d0                	callq  *%rax
  80222a:	c9                   	leaveq 
  80222b:	c3                   	retq   

000000000080222c <sys_vmx_incr_vmdisk_number>:
  80222c:	55                   	push   %rbp
  80222d:	48 89 e5             	mov    %rsp,%rbp
  802230:	48 83 ec 10          	sub    $0x10,%rsp
  802234:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  80223b:	00 
  80223c:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  802242:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  802248:	b9 00 00 00 00       	mov    $0x0,%ecx
  80224d:	ba 00 00 00 00       	mov    $0x0,%edx
  802252:	be 00 00 00 00       	mov    $0x0,%esi
  802257:	bf 16 00 00 00       	mov    $0x16,%edi
  80225c:	48 b8 b6 1b 80 00 00 	movabs $0x801bb6,%rax
  802263:	00 00 00 
  802266:	ff d0                	callq  *%rax
  802268:	c9                   	leaveq 
  802269:	c3                   	retq   

000000000080226a <fd2num>:
  80226a:	55                   	push   %rbp
  80226b:	48 89 e5             	mov    %rsp,%rbp
  80226e:	48 83 ec 08          	sub    $0x8,%rsp
  802272:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802276:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80227a:	48 b8 00 00 00 30 ff 	movabs $0xffffffff30000000,%rax
  802281:	ff ff ff 
  802284:	48 01 d0             	add    %rdx,%rax
  802287:	48 c1 e8 0c          	shr    $0xc,%rax
  80228b:	c9                   	leaveq 
  80228c:	c3                   	retq   

000000000080228d <fd2data>:
  80228d:	55                   	push   %rbp
  80228e:	48 89 e5             	mov    %rsp,%rbp
  802291:	48 83 ec 08          	sub    $0x8,%rsp
  802295:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802299:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80229d:	48 89 c7             	mov    %rax,%rdi
  8022a0:	48 b8 6a 22 80 00 00 	movabs $0x80226a,%rax
  8022a7:	00 00 00 
  8022aa:	ff d0                	callq  *%rax
  8022ac:	48 05 20 00 0d 00    	add    $0xd0020,%rax
  8022b2:	48 c1 e0 0c          	shl    $0xc,%rax
  8022b6:	c9                   	leaveq 
  8022b7:	c3                   	retq   

00000000008022b8 <fd_alloc>:
  8022b8:	55                   	push   %rbp
  8022b9:	48 89 e5             	mov    %rsp,%rbp
  8022bc:	48 83 ec 18          	sub    $0x18,%rsp
  8022c0:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8022c4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8022cb:	eb 6b                	jmp    802338 <fd_alloc+0x80>
  8022cd:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8022d0:	48 98                	cltq   
  8022d2:	48 05 00 00 0d 00    	add    $0xd0000,%rax
  8022d8:	48 c1 e0 0c          	shl    $0xc,%rax
  8022dc:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  8022e0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8022e4:	48 c1 e8 15          	shr    $0x15,%rax
  8022e8:	48 89 c2             	mov    %rax,%rdx
  8022eb:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  8022f2:	01 00 00 
  8022f5:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8022f9:	83 e0 01             	and    $0x1,%eax
  8022fc:	48 85 c0             	test   %rax,%rax
  8022ff:	74 21                	je     802322 <fd_alloc+0x6a>
  802301:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802305:	48 c1 e8 0c          	shr    $0xc,%rax
  802309:	48 89 c2             	mov    %rax,%rdx
  80230c:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  802313:	01 00 00 
  802316:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  80231a:	83 e0 01             	and    $0x1,%eax
  80231d:	48 85 c0             	test   %rax,%rax
  802320:	75 12                	jne    802334 <fd_alloc+0x7c>
  802322:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802326:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80232a:	48 89 10             	mov    %rdx,(%rax)
  80232d:	b8 00 00 00 00       	mov    $0x0,%eax
  802332:	eb 1a                	jmp    80234e <fd_alloc+0x96>
  802334:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  802338:	83 7d fc 1f          	cmpl   $0x1f,-0x4(%rbp)
  80233c:	7e 8f                	jle    8022cd <fd_alloc+0x15>
  80233e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802342:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
  802349:	b8 f5 ff ff ff       	mov    $0xfffffff5,%eax
  80234e:	c9                   	leaveq 
  80234f:	c3                   	retq   

0000000000802350 <fd_lookup>:
  802350:	55                   	push   %rbp
  802351:	48 89 e5             	mov    %rsp,%rbp
  802354:	48 83 ec 20          	sub    $0x20,%rsp
  802358:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80235b:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80235f:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  802363:	78 06                	js     80236b <fd_lookup+0x1b>
  802365:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%rbp)
  802369:	7e 07                	jle    802372 <fd_lookup+0x22>
  80236b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  802370:	eb 6c                	jmp    8023de <fd_lookup+0x8e>
  802372:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802375:	48 98                	cltq   
  802377:	48 05 00 00 0d 00    	add    $0xd0000,%rax
  80237d:	48 c1 e0 0c          	shl    $0xc,%rax
  802381:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  802385:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802389:	48 c1 e8 15          	shr    $0x15,%rax
  80238d:	48 89 c2             	mov    %rax,%rdx
  802390:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  802397:	01 00 00 
  80239a:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  80239e:	83 e0 01             	and    $0x1,%eax
  8023a1:	48 85 c0             	test   %rax,%rax
  8023a4:	74 21                	je     8023c7 <fd_lookup+0x77>
  8023a6:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8023aa:	48 c1 e8 0c          	shr    $0xc,%rax
  8023ae:	48 89 c2             	mov    %rax,%rdx
  8023b1:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  8023b8:	01 00 00 
  8023bb:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8023bf:	83 e0 01             	and    $0x1,%eax
  8023c2:	48 85 c0             	test   %rax,%rax
  8023c5:	75 07                	jne    8023ce <fd_lookup+0x7e>
  8023c7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  8023cc:	eb 10                	jmp    8023de <fd_lookup+0x8e>
  8023ce:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8023d2:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8023d6:	48 89 10             	mov    %rdx,(%rax)
  8023d9:	b8 00 00 00 00       	mov    $0x0,%eax
  8023de:	c9                   	leaveq 
  8023df:	c3                   	retq   

00000000008023e0 <fd_close>:
  8023e0:	55                   	push   %rbp
  8023e1:	48 89 e5             	mov    %rsp,%rbp
  8023e4:	48 83 ec 30          	sub    $0x30,%rsp
  8023e8:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  8023ec:	89 f0                	mov    %esi,%eax
  8023ee:	88 45 d4             	mov    %al,-0x2c(%rbp)
  8023f1:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8023f5:	48 89 c7             	mov    %rax,%rdi
  8023f8:	48 b8 6a 22 80 00 00 	movabs $0x80226a,%rax
  8023ff:	00 00 00 
  802402:	ff d0                	callq  *%rax
  802404:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  802408:	48 89 d6             	mov    %rdx,%rsi
  80240b:	89 c7                	mov    %eax,%edi
  80240d:	48 b8 50 23 80 00 00 	movabs $0x802350,%rax
  802414:	00 00 00 
  802417:	ff d0                	callq  *%rax
  802419:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80241c:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802420:	78 0a                	js     80242c <fd_close+0x4c>
  802422:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802426:	48 39 45 d8          	cmp    %rax,-0x28(%rbp)
  80242a:	74 12                	je     80243e <fd_close+0x5e>
  80242c:	80 7d d4 00          	cmpb   $0x0,-0x2c(%rbp)
  802430:	74 05                	je     802437 <fd_close+0x57>
  802432:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802435:	eb 05                	jmp    80243c <fd_close+0x5c>
  802437:	b8 00 00 00 00       	mov    $0x0,%eax
  80243c:	eb 69                	jmp    8024a7 <fd_close+0xc7>
  80243e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  802442:	8b 00                	mov    (%rax),%eax
  802444:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  802448:	48 89 d6             	mov    %rdx,%rsi
  80244b:	89 c7                	mov    %eax,%edi
  80244d:	48 b8 a9 24 80 00 00 	movabs $0x8024a9,%rax
  802454:	00 00 00 
  802457:	ff d0                	callq  *%rax
  802459:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80245c:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802460:	78 2a                	js     80248c <fd_close+0xac>
  802462:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802466:	48 8b 40 20          	mov    0x20(%rax),%rax
  80246a:	48 85 c0             	test   %rax,%rax
  80246d:	74 16                	je     802485 <fd_close+0xa5>
  80246f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802473:	48 8b 40 20          	mov    0x20(%rax),%rax
  802477:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  80247b:	48 89 d7             	mov    %rdx,%rdi
  80247e:	ff d0                	callq  *%rax
  802480:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802483:	eb 07                	jmp    80248c <fd_close+0xac>
  802485:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  80248c:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  802490:	48 89 c6             	mov    %rax,%rsi
  802493:	bf 00 00 00 00       	mov    $0x0,%edi
  802498:	48 b8 37 1e 80 00 00 	movabs $0x801e37,%rax
  80249f:	00 00 00 
  8024a2:	ff d0                	callq  *%rax
  8024a4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8024a7:	c9                   	leaveq 
  8024a8:	c3                   	retq   

00000000008024a9 <dev_lookup>:
  8024a9:	55                   	push   %rbp
  8024aa:	48 89 e5             	mov    %rsp,%rbp
  8024ad:	48 83 ec 20          	sub    $0x20,%rsp
  8024b1:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8024b4:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8024b8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8024bf:	eb 41                	jmp    802502 <dev_lookup+0x59>
  8024c1:	48 b8 20 60 80 00 00 	movabs $0x806020,%rax
  8024c8:	00 00 00 
  8024cb:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8024ce:	48 63 d2             	movslq %edx,%rdx
  8024d1:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8024d5:	8b 00                	mov    (%rax),%eax
  8024d7:	3b 45 ec             	cmp    -0x14(%rbp),%eax
  8024da:	75 22                	jne    8024fe <dev_lookup+0x55>
  8024dc:	48 b8 20 60 80 00 00 	movabs $0x806020,%rax
  8024e3:	00 00 00 
  8024e6:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8024e9:	48 63 d2             	movslq %edx,%rdx
  8024ec:	48 8b 14 d0          	mov    (%rax,%rdx,8),%rdx
  8024f0:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8024f4:	48 89 10             	mov    %rdx,(%rax)
  8024f7:	b8 00 00 00 00       	mov    $0x0,%eax
  8024fc:	eb 60                	jmp    80255e <dev_lookup+0xb5>
  8024fe:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  802502:	48 b8 20 60 80 00 00 	movabs $0x806020,%rax
  802509:	00 00 00 
  80250c:	8b 55 fc             	mov    -0x4(%rbp),%edx
  80250f:	48 63 d2             	movslq %edx,%rdx
  802512:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802516:	48 85 c0             	test   %rax,%rax
  802519:	75 a6                	jne    8024c1 <dev_lookup+0x18>
  80251b:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  802522:	00 00 00 
  802525:	48 8b 00             	mov    (%rax),%rax
  802528:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  80252e:	8b 55 ec             	mov    -0x14(%rbp),%edx
  802531:	89 c6                	mov    %eax,%esi
  802533:	48 bf f8 4d 80 00 00 	movabs $0x804df8,%rdi
  80253a:	00 00 00 
  80253d:	b8 00 00 00 00       	mov    $0x0,%eax
  802542:	48 b9 a8 08 80 00 00 	movabs $0x8008a8,%rcx
  802549:	00 00 00 
  80254c:	ff d1                	callq  *%rcx
  80254e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802552:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
  802559:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  80255e:	c9                   	leaveq 
  80255f:	c3                   	retq   

0000000000802560 <close>:
  802560:	55                   	push   %rbp
  802561:	48 89 e5             	mov    %rsp,%rbp
  802564:	48 83 ec 20          	sub    $0x20,%rsp
  802568:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80256b:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  80256f:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802572:	48 89 d6             	mov    %rdx,%rsi
  802575:	89 c7                	mov    %eax,%edi
  802577:	48 b8 50 23 80 00 00 	movabs $0x802350,%rax
  80257e:	00 00 00 
  802581:	ff d0                	callq  *%rax
  802583:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802586:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80258a:	79 05                	jns    802591 <close+0x31>
  80258c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80258f:	eb 18                	jmp    8025a9 <close+0x49>
  802591:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802595:	be 01 00 00 00       	mov    $0x1,%esi
  80259a:	48 89 c7             	mov    %rax,%rdi
  80259d:	48 b8 e0 23 80 00 00 	movabs $0x8023e0,%rax
  8025a4:	00 00 00 
  8025a7:	ff d0                	callq  *%rax
  8025a9:	c9                   	leaveq 
  8025aa:	c3                   	retq   

00000000008025ab <close_all>:
  8025ab:	55                   	push   %rbp
  8025ac:	48 89 e5             	mov    %rsp,%rbp
  8025af:	48 83 ec 10          	sub    $0x10,%rsp
  8025b3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8025ba:	eb 15                	jmp    8025d1 <close_all+0x26>
  8025bc:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8025bf:	89 c7                	mov    %eax,%edi
  8025c1:	48 b8 60 25 80 00 00 	movabs $0x802560,%rax
  8025c8:	00 00 00 
  8025cb:	ff d0                	callq  *%rax
  8025cd:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8025d1:	83 7d fc 1f          	cmpl   $0x1f,-0x4(%rbp)
  8025d5:	7e e5                	jle    8025bc <close_all+0x11>
  8025d7:	c9                   	leaveq 
  8025d8:	c3                   	retq   

00000000008025d9 <dup>:
  8025d9:	55                   	push   %rbp
  8025da:	48 89 e5             	mov    %rsp,%rbp
  8025dd:	48 83 ec 40          	sub    $0x40,%rsp
  8025e1:	89 7d cc             	mov    %edi,-0x34(%rbp)
  8025e4:	89 75 c8             	mov    %esi,-0x38(%rbp)
  8025e7:	48 8d 55 d8          	lea    -0x28(%rbp),%rdx
  8025eb:	8b 45 cc             	mov    -0x34(%rbp),%eax
  8025ee:	48 89 d6             	mov    %rdx,%rsi
  8025f1:	89 c7                	mov    %eax,%edi
  8025f3:	48 b8 50 23 80 00 00 	movabs $0x802350,%rax
  8025fa:	00 00 00 
  8025fd:	ff d0                	callq  *%rax
  8025ff:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802602:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802606:	79 08                	jns    802610 <dup+0x37>
  802608:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80260b:	e9 70 01 00 00       	jmpq   802780 <dup+0x1a7>
  802610:	8b 45 c8             	mov    -0x38(%rbp),%eax
  802613:	89 c7                	mov    %eax,%edi
  802615:	48 b8 60 25 80 00 00 	movabs $0x802560,%rax
  80261c:	00 00 00 
  80261f:	ff d0                	callq  *%rax
  802621:	8b 45 c8             	mov    -0x38(%rbp),%eax
  802624:	48 98                	cltq   
  802626:	48 05 00 00 0d 00    	add    $0xd0000,%rax
  80262c:	48 c1 e0 0c          	shl    $0xc,%rax
  802630:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  802634:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  802638:	48 89 c7             	mov    %rax,%rdi
  80263b:	48 b8 8d 22 80 00 00 	movabs $0x80228d,%rax
  802642:	00 00 00 
  802645:	ff d0                	callq  *%rax
  802647:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  80264b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80264f:	48 89 c7             	mov    %rax,%rdi
  802652:	48 b8 8d 22 80 00 00 	movabs $0x80228d,%rax
  802659:	00 00 00 
  80265c:	ff d0                	callq  *%rax
  80265e:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  802662:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802666:	48 c1 e8 15          	shr    $0x15,%rax
  80266a:	48 89 c2             	mov    %rax,%rdx
  80266d:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  802674:	01 00 00 
  802677:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  80267b:	83 e0 01             	and    $0x1,%eax
  80267e:	48 85 c0             	test   %rax,%rax
  802681:	74 73                	je     8026f6 <dup+0x11d>
  802683:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802687:	48 c1 e8 0c          	shr    $0xc,%rax
  80268b:	48 89 c2             	mov    %rax,%rdx
  80268e:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  802695:	01 00 00 
  802698:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  80269c:	83 e0 01             	and    $0x1,%eax
  80269f:	48 85 c0             	test   %rax,%rax
  8026a2:	74 52                	je     8026f6 <dup+0x11d>
  8026a4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8026a8:	48 c1 e8 0c          	shr    $0xc,%rax
  8026ac:	48 89 c2             	mov    %rax,%rdx
  8026af:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  8026b6:	01 00 00 
  8026b9:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8026bd:	25 07 0e 00 00       	and    $0xe07,%eax
  8026c2:	89 c1                	mov    %eax,%ecx
  8026c4:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8026c8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8026cc:	41 89 c8             	mov    %ecx,%r8d
  8026cf:	48 89 d1             	mov    %rdx,%rcx
  8026d2:	ba 00 00 00 00       	mov    $0x0,%edx
  8026d7:	48 89 c6             	mov    %rax,%rsi
  8026da:	bf 00 00 00 00       	mov    $0x0,%edi
  8026df:	48 b8 dc 1d 80 00 00 	movabs $0x801ddc,%rax
  8026e6:	00 00 00 
  8026e9:	ff d0                	callq  *%rax
  8026eb:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8026ee:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8026f2:	79 02                	jns    8026f6 <dup+0x11d>
  8026f4:	eb 57                	jmp    80274d <dup+0x174>
  8026f6:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8026fa:	48 c1 e8 0c          	shr    $0xc,%rax
  8026fe:	48 89 c2             	mov    %rax,%rdx
  802701:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  802708:	01 00 00 
  80270b:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  80270f:	25 07 0e 00 00       	and    $0xe07,%eax
  802714:	89 c1                	mov    %eax,%ecx
  802716:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80271a:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80271e:	41 89 c8             	mov    %ecx,%r8d
  802721:	48 89 d1             	mov    %rdx,%rcx
  802724:	ba 00 00 00 00       	mov    $0x0,%edx
  802729:	48 89 c6             	mov    %rax,%rsi
  80272c:	bf 00 00 00 00       	mov    $0x0,%edi
  802731:	48 b8 dc 1d 80 00 00 	movabs $0x801ddc,%rax
  802738:	00 00 00 
  80273b:	ff d0                	callq  *%rax
  80273d:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802740:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802744:	79 02                	jns    802748 <dup+0x16f>
  802746:	eb 05                	jmp    80274d <dup+0x174>
  802748:	8b 45 c8             	mov    -0x38(%rbp),%eax
  80274b:	eb 33                	jmp    802780 <dup+0x1a7>
  80274d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802751:	48 89 c6             	mov    %rax,%rsi
  802754:	bf 00 00 00 00       	mov    $0x0,%edi
  802759:	48 b8 37 1e 80 00 00 	movabs $0x801e37,%rax
  802760:	00 00 00 
  802763:	ff d0                	callq  *%rax
  802765:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802769:	48 89 c6             	mov    %rax,%rsi
  80276c:	bf 00 00 00 00       	mov    $0x0,%edi
  802771:	48 b8 37 1e 80 00 00 	movabs $0x801e37,%rax
  802778:	00 00 00 
  80277b:	ff d0                	callq  *%rax
  80277d:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802780:	c9                   	leaveq 
  802781:	c3                   	retq   

0000000000802782 <read>:
  802782:	55                   	push   %rbp
  802783:	48 89 e5             	mov    %rsp,%rbp
  802786:	48 83 ec 40          	sub    $0x40,%rsp
  80278a:	89 7d dc             	mov    %edi,-0x24(%rbp)
  80278d:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  802791:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  802795:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  802799:	8b 45 dc             	mov    -0x24(%rbp),%eax
  80279c:	48 89 d6             	mov    %rdx,%rsi
  80279f:	89 c7                	mov    %eax,%edi
  8027a1:	48 b8 50 23 80 00 00 	movabs $0x802350,%rax
  8027a8:	00 00 00 
  8027ab:	ff d0                	callq  *%rax
  8027ad:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8027b0:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8027b4:	78 24                	js     8027da <read+0x58>
  8027b6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8027ba:	8b 00                	mov    (%rax),%eax
  8027bc:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  8027c0:	48 89 d6             	mov    %rdx,%rsi
  8027c3:	89 c7                	mov    %eax,%edi
  8027c5:	48 b8 a9 24 80 00 00 	movabs $0x8024a9,%rax
  8027cc:	00 00 00 
  8027cf:	ff d0                	callq  *%rax
  8027d1:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8027d4:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8027d8:	79 05                	jns    8027df <read+0x5d>
  8027da:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8027dd:	eb 76                	jmp    802855 <read+0xd3>
  8027df:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8027e3:	8b 40 08             	mov    0x8(%rax),%eax
  8027e6:	83 e0 03             	and    $0x3,%eax
  8027e9:	83 f8 01             	cmp    $0x1,%eax
  8027ec:	75 3a                	jne    802828 <read+0xa6>
  8027ee:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  8027f5:	00 00 00 
  8027f8:	48 8b 00             	mov    (%rax),%rax
  8027fb:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  802801:	8b 55 dc             	mov    -0x24(%rbp),%edx
  802804:	89 c6                	mov    %eax,%esi
  802806:	48 bf 17 4e 80 00 00 	movabs $0x804e17,%rdi
  80280d:	00 00 00 
  802810:	b8 00 00 00 00       	mov    $0x0,%eax
  802815:	48 b9 a8 08 80 00 00 	movabs $0x8008a8,%rcx
  80281c:	00 00 00 
  80281f:	ff d1                	callq  *%rcx
  802821:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  802826:	eb 2d                	jmp    802855 <read+0xd3>
  802828:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80282c:	48 8b 40 10          	mov    0x10(%rax),%rax
  802830:	48 85 c0             	test   %rax,%rax
  802833:	75 07                	jne    80283c <read+0xba>
  802835:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  80283a:	eb 19                	jmp    802855 <read+0xd3>
  80283c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802840:	48 8b 40 10          	mov    0x10(%rax),%rax
  802844:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  802848:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80284c:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  802850:	48 89 cf             	mov    %rcx,%rdi
  802853:	ff d0                	callq  *%rax
  802855:	c9                   	leaveq 
  802856:	c3                   	retq   

0000000000802857 <readn>:
  802857:	55                   	push   %rbp
  802858:	48 89 e5             	mov    %rsp,%rbp
  80285b:	48 83 ec 30          	sub    $0x30,%rsp
  80285f:	89 7d ec             	mov    %edi,-0x14(%rbp)
  802862:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802866:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80286a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  802871:	eb 49                	jmp    8028bc <readn+0x65>
  802873:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802876:	48 98                	cltq   
  802878:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  80287c:	48 29 c2             	sub    %rax,%rdx
  80287f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802882:	48 63 c8             	movslq %eax,%rcx
  802885:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802889:	48 01 c1             	add    %rax,%rcx
  80288c:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80288f:	48 89 ce             	mov    %rcx,%rsi
  802892:	89 c7                	mov    %eax,%edi
  802894:	48 b8 82 27 80 00 00 	movabs $0x802782,%rax
  80289b:	00 00 00 
  80289e:	ff d0                	callq  *%rax
  8028a0:	89 45 f8             	mov    %eax,-0x8(%rbp)
  8028a3:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8028a7:	79 05                	jns    8028ae <readn+0x57>
  8028a9:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8028ac:	eb 1c                	jmp    8028ca <readn+0x73>
  8028ae:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8028b2:	75 02                	jne    8028b6 <readn+0x5f>
  8028b4:	eb 11                	jmp    8028c7 <readn+0x70>
  8028b6:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8028b9:	01 45 fc             	add    %eax,-0x4(%rbp)
  8028bc:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8028bf:	48 98                	cltq   
  8028c1:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  8028c5:	72 ac                	jb     802873 <readn+0x1c>
  8028c7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8028ca:	c9                   	leaveq 
  8028cb:	c3                   	retq   

00000000008028cc <write>:
  8028cc:	55                   	push   %rbp
  8028cd:	48 89 e5             	mov    %rsp,%rbp
  8028d0:	48 83 ec 40          	sub    $0x40,%rsp
  8028d4:	89 7d dc             	mov    %edi,-0x24(%rbp)
  8028d7:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  8028db:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  8028df:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  8028e3:	8b 45 dc             	mov    -0x24(%rbp),%eax
  8028e6:	48 89 d6             	mov    %rdx,%rsi
  8028e9:	89 c7                	mov    %eax,%edi
  8028eb:	48 b8 50 23 80 00 00 	movabs $0x802350,%rax
  8028f2:	00 00 00 
  8028f5:	ff d0                	callq  *%rax
  8028f7:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8028fa:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8028fe:	78 24                	js     802924 <write+0x58>
  802900:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802904:	8b 00                	mov    (%rax),%eax
  802906:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  80290a:	48 89 d6             	mov    %rdx,%rsi
  80290d:	89 c7                	mov    %eax,%edi
  80290f:	48 b8 a9 24 80 00 00 	movabs $0x8024a9,%rax
  802916:	00 00 00 
  802919:	ff d0                	callq  *%rax
  80291b:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80291e:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802922:	79 05                	jns    802929 <write+0x5d>
  802924:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802927:	eb 75                	jmp    80299e <write+0xd2>
  802929:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80292d:	8b 40 08             	mov    0x8(%rax),%eax
  802930:	83 e0 03             	and    $0x3,%eax
  802933:	85 c0                	test   %eax,%eax
  802935:	75 3a                	jne    802971 <write+0xa5>
  802937:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  80293e:	00 00 00 
  802941:	48 8b 00             	mov    (%rax),%rax
  802944:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  80294a:	8b 55 dc             	mov    -0x24(%rbp),%edx
  80294d:	89 c6                	mov    %eax,%esi
  80294f:	48 bf 33 4e 80 00 00 	movabs $0x804e33,%rdi
  802956:	00 00 00 
  802959:	b8 00 00 00 00       	mov    $0x0,%eax
  80295e:	48 b9 a8 08 80 00 00 	movabs $0x8008a8,%rcx
  802965:	00 00 00 
  802968:	ff d1                	callq  *%rcx
  80296a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  80296f:	eb 2d                	jmp    80299e <write+0xd2>
  802971:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802975:	48 8b 40 18          	mov    0x18(%rax),%rax
  802979:	48 85 c0             	test   %rax,%rax
  80297c:	75 07                	jne    802985 <write+0xb9>
  80297e:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  802983:	eb 19                	jmp    80299e <write+0xd2>
  802985:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802989:	48 8b 40 18          	mov    0x18(%rax),%rax
  80298d:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  802991:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  802995:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  802999:	48 89 cf             	mov    %rcx,%rdi
  80299c:	ff d0                	callq  *%rax
  80299e:	c9                   	leaveq 
  80299f:	c3                   	retq   

00000000008029a0 <seek>:
  8029a0:	55                   	push   %rbp
  8029a1:	48 89 e5             	mov    %rsp,%rbp
  8029a4:	48 83 ec 18          	sub    $0x18,%rsp
  8029a8:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8029ab:	89 75 e8             	mov    %esi,-0x18(%rbp)
  8029ae:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  8029b2:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8029b5:	48 89 d6             	mov    %rdx,%rsi
  8029b8:	89 c7                	mov    %eax,%edi
  8029ba:	48 b8 50 23 80 00 00 	movabs $0x802350,%rax
  8029c1:	00 00 00 
  8029c4:	ff d0                	callq  *%rax
  8029c6:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8029c9:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8029cd:	79 05                	jns    8029d4 <seek+0x34>
  8029cf:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8029d2:	eb 0f                	jmp    8029e3 <seek+0x43>
  8029d4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8029d8:	8b 55 e8             	mov    -0x18(%rbp),%edx
  8029db:	89 50 04             	mov    %edx,0x4(%rax)
  8029de:	b8 00 00 00 00       	mov    $0x0,%eax
  8029e3:	c9                   	leaveq 
  8029e4:	c3                   	retq   

00000000008029e5 <ftruncate>:
  8029e5:	55                   	push   %rbp
  8029e6:	48 89 e5             	mov    %rsp,%rbp
  8029e9:	48 83 ec 30          	sub    $0x30,%rsp
  8029ed:	89 7d dc             	mov    %edi,-0x24(%rbp)
  8029f0:	89 75 d8             	mov    %esi,-0x28(%rbp)
  8029f3:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  8029f7:	8b 45 dc             	mov    -0x24(%rbp),%eax
  8029fa:	48 89 d6             	mov    %rdx,%rsi
  8029fd:	89 c7                	mov    %eax,%edi
  8029ff:	48 b8 50 23 80 00 00 	movabs $0x802350,%rax
  802a06:	00 00 00 
  802a09:	ff d0                	callq  *%rax
  802a0b:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802a0e:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802a12:	78 24                	js     802a38 <ftruncate+0x53>
  802a14:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802a18:	8b 00                	mov    (%rax),%eax
  802a1a:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  802a1e:	48 89 d6             	mov    %rdx,%rsi
  802a21:	89 c7                	mov    %eax,%edi
  802a23:	48 b8 a9 24 80 00 00 	movabs $0x8024a9,%rax
  802a2a:	00 00 00 
  802a2d:	ff d0                	callq  *%rax
  802a2f:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802a32:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802a36:	79 05                	jns    802a3d <ftruncate+0x58>
  802a38:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802a3b:	eb 72                	jmp    802aaf <ftruncate+0xca>
  802a3d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802a41:	8b 40 08             	mov    0x8(%rax),%eax
  802a44:	83 e0 03             	and    $0x3,%eax
  802a47:	85 c0                	test   %eax,%eax
  802a49:	75 3a                	jne    802a85 <ftruncate+0xa0>
  802a4b:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  802a52:	00 00 00 
  802a55:	48 8b 00             	mov    (%rax),%rax
  802a58:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  802a5e:	8b 55 dc             	mov    -0x24(%rbp),%edx
  802a61:	89 c6                	mov    %eax,%esi
  802a63:	48 bf 50 4e 80 00 00 	movabs $0x804e50,%rdi
  802a6a:	00 00 00 
  802a6d:	b8 00 00 00 00       	mov    $0x0,%eax
  802a72:	48 b9 a8 08 80 00 00 	movabs $0x8008a8,%rcx
  802a79:	00 00 00 
  802a7c:	ff d1                	callq  *%rcx
  802a7e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  802a83:	eb 2a                	jmp    802aaf <ftruncate+0xca>
  802a85:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802a89:	48 8b 40 30          	mov    0x30(%rax),%rax
  802a8d:	48 85 c0             	test   %rax,%rax
  802a90:	75 07                	jne    802a99 <ftruncate+0xb4>
  802a92:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  802a97:	eb 16                	jmp    802aaf <ftruncate+0xca>
  802a99:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802a9d:	48 8b 40 30          	mov    0x30(%rax),%rax
  802aa1:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  802aa5:	8b 4d d8             	mov    -0x28(%rbp),%ecx
  802aa8:	89 ce                	mov    %ecx,%esi
  802aaa:	48 89 d7             	mov    %rdx,%rdi
  802aad:	ff d0                	callq  *%rax
  802aaf:	c9                   	leaveq 
  802ab0:	c3                   	retq   

0000000000802ab1 <fstat>:
  802ab1:	55                   	push   %rbp
  802ab2:	48 89 e5             	mov    %rsp,%rbp
  802ab5:	48 83 ec 30          	sub    $0x30,%rsp
  802ab9:	89 7d dc             	mov    %edi,-0x24(%rbp)
  802abc:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  802ac0:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  802ac4:	8b 45 dc             	mov    -0x24(%rbp),%eax
  802ac7:	48 89 d6             	mov    %rdx,%rsi
  802aca:	89 c7                	mov    %eax,%edi
  802acc:	48 b8 50 23 80 00 00 	movabs $0x802350,%rax
  802ad3:	00 00 00 
  802ad6:	ff d0                	callq  *%rax
  802ad8:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802adb:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802adf:	78 24                	js     802b05 <fstat+0x54>
  802ae1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802ae5:	8b 00                	mov    (%rax),%eax
  802ae7:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  802aeb:	48 89 d6             	mov    %rdx,%rsi
  802aee:	89 c7                	mov    %eax,%edi
  802af0:	48 b8 a9 24 80 00 00 	movabs $0x8024a9,%rax
  802af7:	00 00 00 
  802afa:	ff d0                	callq  *%rax
  802afc:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802aff:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802b03:	79 05                	jns    802b0a <fstat+0x59>
  802b05:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802b08:	eb 5e                	jmp    802b68 <fstat+0xb7>
  802b0a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802b0e:	48 8b 40 28          	mov    0x28(%rax),%rax
  802b12:	48 85 c0             	test   %rax,%rax
  802b15:	75 07                	jne    802b1e <fstat+0x6d>
  802b17:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  802b1c:	eb 4a                	jmp    802b68 <fstat+0xb7>
  802b1e:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802b22:	c6 00 00             	movb   $0x0,(%rax)
  802b25:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802b29:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%rax)
  802b30:	00 00 00 
  802b33:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802b37:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%rax)
  802b3e:	00 00 00 
  802b41:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  802b45:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802b49:	48 89 90 88 00 00 00 	mov    %rdx,0x88(%rax)
  802b50:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802b54:	48 8b 40 28          	mov    0x28(%rax),%rax
  802b58:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  802b5c:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  802b60:	48 89 ce             	mov    %rcx,%rsi
  802b63:	48 89 d7             	mov    %rdx,%rdi
  802b66:	ff d0                	callq  *%rax
  802b68:	c9                   	leaveq 
  802b69:	c3                   	retq   

0000000000802b6a <stat>:
  802b6a:	55                   	push   %rbp
  802b6b:	48 89 e5             	mov    %rsp,%rbp
  802b6e:	48 83 ec 20          	sub    $0x20,%rsp
  802b72:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802b76:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802b7a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802b7e:	be 00 00 00 00       	mov    $0x0,%esi
  802b83:	48 89 c7             	mov    %rax,%rdi
  802b86:	48 b8 58 2c 80 00 00 	movabs $0x802c58,%rax
  802b8d:	00 00 00 
  802b90:	ff d0                	callq  *%rax
  802b92:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802b95:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802b99:	79 05                	jns    802ba0 <stat+0x36>
  802b9b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802b9e:	eb 2f                	jmp    802bcf <stat+0x65>
  802ba0:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  802ba4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802ba7:	48 89 d6             	mov    %rdx,%rsi
  802baa:	89 c7                	mov    %eax,%edi
  802bac:	48 b8 b1 2a 80 00 00 	movabs $0x802ab1,%rax
  802bb3:	00 00 00 
  802bb6:	ff d0                	callq  *%rax
  802bb8:	89 45 f8             	mov    %eax,-0x8(%rbp)
  802bbb:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802bbe:	89 c7                	mov    %eax,%edi
  802bc0:	48 b8 60 25 80 00 00 	movabs $0x802560,%rax
  802bc7:	00 00 00 
  802bca:	ff d0                	callq  *%rax
  802bcc:	8b 45 f8             	mov    -0x8(%rbp),%eax
  802bcf:	c9                   	leaveq 
  802bd0:	c3                   	retq   

0000000000802bd1 <fsipc>:
  802bd1:	55                   	push   %rbp
  802bd2:	48 89 e5             	mov    %rsp,%rbp
  802bd5:	48 83 ec 10          	sub    $0x10,%rsp
  802bd9:	89 7d fc             	mov    %edi,-0x4(%rbp)
  802bdc:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  802be0:	48 b8 00 70 80 00 00 	movabs $0x807000,%rax
  802be7:	00 00 00 
  802bea:	8b 00                	mov    (%rax),%eax
  802bec:	85 c0                	test   %eax,%eax
  802bee:	75 1d                	jne    802c0d <fsipc+0x3c>
  802bf0:	bf 01 00 00 00       	mov    $0x1,%edi
  802bf5:	48 b8 1d 46 80 00 00 	movabs $0x80461d,%rax
  802bfc:	00 00 00 
  802bff:	ff d0                	callq  *%rax
  802c01:	48 ba 00 70 80 00 00 	movabs $0x807000,%rdx
  802c08:	00 00 00 
  802c0b:	89 02                	mov    %eax,(%rdx)
  802c0d:	48 b8 00 70 80 00 00 	movabs $0x807000,%rax
  802c14:	00 00 00 
  802c17:	8b 00                	mov    (%rax),%eax
  802c19:	8b 75 fc             	mov    -0x4(%rbp),%esi
  802c1c:	b9 07 00 00 00       	mov    $0x7,%ecx
  802c21:	48 ba 00 80 80 00 00 	movabs $0x808000,%rdx
  802c28:	00 00 00 
  802c2b:	89 c7                	mov    %eax,%edi
  802c2d:	48 b8 87 45 80 00 00 	movabs $0x804587,%rax
  802c34:	00 00 00 
  802c37:	ff d0                	callq  *%rax
  802c39:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802c3d:	ba 00 00 00 00       	mov    $0x0,%edx
  802c42:	48 89 c6             	mov    %rax,%rsi
  802c45:	bf 00 00 00 00       	mov    $0x0,%edi
  802c4a:	48 b8 c6 44 80 00 00 	movabs $0x8044c6,%rax
  802c51:	00 00 00 
  802c54:	ff d0                	callq  *%rax
  802c56:	c9                   	leaveq 
  802c57:	c3                   	retq   

0000000000802c58 <open>:
  802c58:	55                   	push   %rbp
  802c59:	48 89 e5             	mov    %rsp,%rbp
  802c5c:	48 83 ec 20          	sub    $0x20,%rsp
  802c60:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802c64:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  802c67:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802c6b:	48 89 c7             	mov    %rax,%rdi
  802c6e:	48 b8 f1 13 80 00 00 	movabs $0x8013f1,%rax
  802c75:	00 00 00 
  802c78:	ff d0                	callq  *%rax
  802c7a:	3d ff 03 00 00       	cmp    $0x3ff,%eax
  802c7f:	7e 0a                	jle    802c8b <open+0x33>
  802c81:	b8 f3 ff ff ff       	mov    $0xfffffff3,%eax
  802c86:	e9 a5 00 00 00       	jmpq   802d30 <open+0xd8>
  802c8b:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  802c8f:	48 89 c7             	mov    %rax,%rdi
  802c92:	48 b8 b8 22 80 00 00 	movabs $0x8022b8,%rax
  802c99:	00 00 00 
  802c9c:	ff d0                	callq  *%rax
  802c9e:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802ca1:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802ca5:	79 08                	jns    802caf <open+0x57>
  802ca7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802caa:	e9 81 00 00 00       	jmpq   802d30 <open+0xd8>
  802caf:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802cb3:	48 89 c6             	mov    %rax,%rsi
  802cb6:	48 bf 00 80 80 00 00 	movabs $0x808000,%rdi
  802cbd:	00 00 00 
  802cc0:	48 b8 5d 14 80 00 00 	movabs $0x80145d,%rax
  802cc7:	00 00 00 
  802cca:	ff d0                	callq  *%rax
  802ccc:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802cd3:	00 00 00 
  802cd6:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  802cd9:	89 90 00 04 00 00    	mov    %edx,0x400(%rax)
  802cdf:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802ce3:	48 89 c6             	mov    %rax,%rsi
  802ce6:	bf 01 00 00 00       	mov    $0x1,%edi
  802ceb:	48 b8 d1 2b 80 00 00 	movabs $0x802bd1,%rax
  802cf2:	00 00 00 
  802cf5:	ff d0                	callq  *%rax
  802cf7:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802cfa:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802cfe:	79 1d                	jns    802d1d <open+0xc5>
  802d00:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802d04:	be 00 00 00 00       	mov    $0x0,%esi
  802d09:	48 89 c7             	mov    %rax,%rdi
  802d0c:	48 b8 e0 23 80 00 00 	movabs $0x8023e0,%rax
  802d13:	00 00 00 
  802d16:	ff d0                	callq  *%rax
  802d18:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802d1b:	eb 13                	jmp    802d30 <open+0xd8>
  802d1d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802d21:	48 89 c7             	mov    %rax,%rdi
  802d24:	48 b8 6a 22 80 00 00 	movabs $0x80226a,%rax
  802d2b:	00 00 00 
  802d2e:	ff d0                	callq  *%rax
  802d30:	c9                   	leaveq 
  802d31:	c3                   	retq   

0000000000802d32 <devfile_flush>:
  802d32:	55                   	push   %rbp
  802d33:	48 89 e5             	mov    %rsp,%rbp
  802d36:	48 83 ec 10          	sub    $0x10,%rsp
  802d3a:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802d3e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802d42:	8b 50 0c             	mov    0xc(%rax),%edx
  802d45:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802d4c:	00 00 00 
  802d4f:	89 10                	mov    %edx,(%rax)
  802d51:	be 00 00 00 00       	mov    $0x0,%esi
  802d56:	bf 06 00 00 00       	mov    $0x6,%edi
  802d5b:	48 b8 d1 2b 80 00 00 	movabs $0x802bd1,%rax
  802d62:	00 00 00 
  802d65:	ff d0                	callq  *%rax
  802d67:	c9                   	leaveq 
  802d68:	c3                   	retq   

0000000000802d69 <devfile_read>:
  802d69:	55                   	push   %rbp
  802d6a:	48 89 e5             	mov    %rsp,%rbp
  802d6d:	48 83 ec 30          	sub    $0x30,%rsp
  802d71:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802d75:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802d79:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  802d7d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802d81:	8b 50 0c             	mov    0xc(%rax),%edx
  802d84:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802d8b:	00 00 00 
  802d8e:	89 10                	mov    %edx,(%rax)
  802d90:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802d97:	00 00 00 
  802d9a:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  802d9e:	48 89 50 08          	mov    %rdx,0x8(%rax)
  802da2:	be 00 00 00 00       	mov    $0x0,%esi
  802da7:	bf 03 00 00 00       	mov    $0x3,%edi
  802dac:	48 b8 d1 2b 80 00 00 	movabs $0x802bd1,%rax
  802db3:	00 00 00 
  802db6:	ff d0                	callq  *%rax
  802db8:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802dbb:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802dbf:	79 08                	jns    802dc9 <devfile_read+0x60>
  802dc1:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802dc4:	e9 a4 00 00 00       	jmpq   802e6d <devfile_read+0x104>
  802dc9:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802dcc:	48 98                	cltq   
  802dce:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  802dd2:	76 35                	jbe    802e09 <devfile_read+0xa0>
  802dd4:	48 b9 76 4e 80 00 00 	movabs $0x804e76,%rcx
  802ddb:	00 00 00 
  802dde:	48 ba 7d 4e 80 00 00 	movabs $0x804e7d,%rdx
  802de5:	00 00 00 
  802de8:	be 89 00 00 00       	mov    $0x89,%esi
  802ded:	48 bf 92 4e 80 00 00 	movabs $0x804e92,%rdi
  802df4:	00 00 00 
  802df7:	b8 00 00 00 00       	mov    $0x0,%eax
  802dfc:	49 b8 b2 43 80 00 00 	movabs $0x8043b2,%r8
  802e03:	00 00 00 
  802e06:	41 ff d0             	callq  *%r8
  802e09:	81 7d fc 00 10 00 00 	cmpl   $0x1000,-0x4(%rbp)
  802e10:	7e 35                	jle    802e47 <devfile_read+0xde>
  802e12:	48 b9 a0 4e 80 00 00 	movabs $0x804ea0,%rcx
  802e19:	00 00 00 
  802e1c:	48 ba 7d 4e 80 00 00 	movabs $0x804e7d,%rdx
  802e23:	00 00 00 
  802e26:	be 8a 00 00 00       	mov    $0x8a,%esi
  802e2b:	48 bf 92 4e 80 00 00 	movabs $0x804e92,%rdi
  802e32:	00 00 00 
  802e35:	b8 00 00 00 00       	mov    $0x0,%eax
  802e3a:	49 b8 b2 43 80 00 00 	movabs $0x8043b2,%r8
  802e41:	00 00 00 
  802e44:	41 ff d0             	callq  *%r8
  802e47:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802e4a:	48 63 d0             	movslq %eax,%rdx
  802e4d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802e51:	48 be 00 80 80 00 00 	movabs $0x808000,%rsi
  802e58:	00 00 00 
  802e5b:	48 89 c7             	mov    %rax,%rdi
  802e5e:	48 b8 81 17 80 00 00 	movabs $0x801781,%rax
  802e65:	00 00 00 
  802e68:	ff d0                	callq  *%rax
  802e6a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802e6d:	c9                   	leaveq 
  802e6e:	c3                   	retq   

0000000000802e6f <devfile_write>:
  802e6f:	55                   	push   %rbp
  802e70:	48 89 e5             	mov    %rsp,%rbp
  802e73:	48 83 ec 40          	sub    $0x40,%rsp
  802e77:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  802e7b:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  802e7f:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  802e83:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  802e87:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  802e8b:	48 c7 45 f0 f4 0f 00 	movq   $0xff4,-0x10(%rbp)
  802e92:	00 
  802e93:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802e97:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  802e9b:	48 0f 46 45 f8       	cmovbe -0x8(%rbp),%rax
  802ea0:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
  802ea4:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  802ea8:	8b 50 0c             	mov    0xc(%rax),%edx
  802eab:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802eb2:	00 00 00 
  802eb5:	89 10                	mov    %edx,(%rax)
  802eb7:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802ebe:	00 00 00 
  802ec1:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  802ec5:	48 89 50 08          	mov    %rdx,0x8(%rax)
  802ec9:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  802ecd:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802ed1:	48 89 c6             	mov    %rax,%rsi
  802ed4:	48 bf 10 80 80 00 00 	movabs $0x808010,%rdi
  802edb:	00 00 00 
  802ede:	48 b8 81 17 80 00 00 	movabs $0x801781,%rax
  802ee5:	00 00 00 
  802ee8:	ff d0                	callq  *%rax
  802eea:	be 00 00 00 00       	mov    $0x0,%esi
  802eef:	bf 04 00 00 00       	mov    $0x4,%edi
  802ef4:	48 b8 d1 2b 80 00 00 	movabs $0x802bd1,%rax
  802efb:	00 00 00 
  802efe:	ff d0                	callq  *%rax
  802f00:	89 45 ec             	mov    %eax,-0x14(%rbp)
  802f03:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  802f07:	79 05                	jns    802f0e <devfile_write+0x9f>
  802f09:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802f0c:	eb 43                	jmp    802f51 <devfile_write+0xe2>
  802f0e:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802f11:	48 98                	cltq   
  802f13:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  802f17:	76 35                	jbe    802f4e <devfile_write+0xdf>
  802f19:	48 b9 76 4e 80 00 00 	movabs $0x804e76,%rcx
  802f20:	00 00 00 
  802f23:	48 ba 7d 4e 80 00 00 	movabs $0x804e7d,%rdx
  802f2a:	00 00 00 
  802f2d:	be a8 00 00 00       	mov    $0xa8,%esi
  802f32:	48 bf 92 4e 80 00 00 	movabs $0x804e92,%rdi
  802f39:	00 00 00 
  802f3c:	b8 00 00 00 00       	mov    $0x0,%eax
  802f41:	49 b8 b2 43 80 00 00 	movabs $0x8043b2,%r8
  802f48:	00 00 00 
  802f4b:	41 ff d0             	callq  *%r8
  802f4e:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802f51:	c9                   	leaveq 
  802f52:	c3                   	retq   

0000000000802f53 <devfile_stat>:
  802f53:	55                   	push   %rbp
  802f54:	48 89 e5             	mov    %rsp,%rbp
  802f57:	48 83 ec 20          	sub    $0x20,%rsp
  802f5b:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802f5f:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802f63:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802f67:	8b 50 0c             	mov    0xc(%rax),%edx
  802f6a:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802f71:	00 00 00 
  802f74:	89 10                	mov    %edx,(%rax)
  802f76:	be 00 00 00 00       	mov    $0x0,%esi
  802f7b:	bf 05 00 00 00       	mov    $0x5,%edi
  802f80:	48 b8 d1 2b 80 00 00 	movabs $0x802bd1,%rax
  802f87:	00 00 00 
  802f8a:	ff d0                	callq  *%rax
  802f8c:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802f8f:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802f93:	79 05                	jns    802f9a <devfile_stat+0x47>
  802f95:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802f98:	eb 56                	jmp    802ff0 <devfile_stat+0x9d>
  802f9a:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802f9e:	48 be 00 80 80 00 00 	movabs $0x808000,%rsi
  802fa5:	00 00 00 
  802fa8:	48 89 c7             	mov    %rax,%rdi
  802fab:	48 b8 5d 14 80 00 00 	movabs $0x80145d,%rax
  802fb2:	00 00 00 
  802fb5:	ff d0                	callq  *%rax
  802fb7:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802fbe:	00 00 00 
  802fc1:	8b 90 80 00 00 00    	mov    0x80(%rax),%edx
  802fc7:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802fcb:	89 90 80 00 00 00    	mov    %edx,0x80(%rax)
  802fd1:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802fd8:	00 00 00 
  802fdb:	8b 90 84 00 00 00    	mov    0x84(%rax),%edx
  802fe1:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802fe5:	89 90 84 00 00 00    	mov    %edx,0x84(%rax)
  802feb:	b8 00 00 00 00       	mov    $0x0,%eax
  802ff0:	c9                   	leaveq 
  802ff1:	c3                   	retq   

0000000000802ff2 <devfile_trunc>:
  802ff2:	55                   	push   %rbp
  802ff3:	48 89 e5             	mov    %rsp,%rbp
  802ff6:	48 83 ec 10          	sub    $0x10,%rsp
  802ffa:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802ffe:	89 75 f4             	mov    %esi,-0xc(%rbp)
  803001:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803005:	8b 50 0c             	mov    0xc(%rax),%edx
  803008:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  80300f:	00 00 00 
  803012:	89 10                	mov    %edx,(%rax)
  803014:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  80301b:	00 00 00 
  80301e:	8b 55 f4             	mov    -0xc(%rbp),%edx
  803021:	89 50 04             	mov    %edx,0x4(%rax)
  803024:	be 00 00 00 00       	mov    $0x0,%esi
  803029:	bf 02 00 00 00       	mov    $0x2,%edi
  80302e:	48 b8 d1 2b 80 00 00 	movabs $0x802bd1,%rax
  803035:	00 00 00 
  803038:	ff d0                	callq  *%rax
  80303a:	c9                   	leaveq 
  80303b:	c3                   	retq   

000000000080303c <remove>:
  80303c:	55                   	push   %rbp
  80303d:	48 89 e5             	mov    %rsp,%rbp
  803040:	48 83 ec 10          	sub    $0x10,%rsp
  803044:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  803048:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80304c:	48 89 c7             	mov    %rax,%rdi
  80304f:	48 b8 f1 13 80 00 00 	movabs $0x8013f1,%rax
  803056:	00 00 00 
  803059:	ff d0                	callq  *%rax
  80305b:	3d ff 03 00 00       	cmp    $0x3ff,%eax
  803060:	7e 07                	jle    803069 <remove+0x2d>
  803062:	b8 f3 ff ff ff       	mov    $0xfffffff3,%eax
  803067:	eb 33                	jmp    80309c <remove+0x60>
  803069:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80306d:	48 89 c6             	mov    %rax,%rsi
  803070:	48 bf 00 80 80 00 00 	movabs $0x808000,%rdi
  803077:	00 00 00 
  80307a:	48 b8 5d 14 80 00 00 	movabs $0x80145d,%rax
  803081:	00 00 00 
  803084:	ff d0                	callq  *%rax
  803086:	be 00 00 00 00       	mov    $0x0,%esi
  80308b:	bf 07 00 00 00       	mov    $0x7,%edi
  803090:	48 b8 d1 2b 80 00 00 	movabs $0x802bd1,%rax
  803097:	00 00 00 
  80309a:	ff d0                	callq  *%rax
  80309c:	c9                   	leaveq 
  80309d:	c3                   	retq   

000000000080309e <sync>:
  80309e:	55                   	push   %rbp
  80309f:	48 89 e5             	mov    %rsp,%rbp
  8030a2:	be 00 00 00 00       	mov    $0x0,%esi
  8030a7:	bf 08 00 00 00       	mov    $0x8,%edi
  8030ac:	48 b8 d1 2b 80 00 00 	movabs $0x802bd1,%rax
  8030b3:	00 00 00 
  8030b6:	ff d0                	callq  *%rax
  8030b8:	5d                   	pop    %rbp
  8030b9:	c3                   	retq   

00000000008030ba <copy>:
  8030ba:	55                   	push   %rbp
  8030bb:	48 89 e5             	mov    %rsp,%rbp
  8030be:	48 81 ec 20 02 00 00 	sub    $0x220,%rsp
  8030c5:	48 89 bd e8 fd ff ff 	mov    %rdi,-0x218(%rbp)
  8030cc:	48 89 b5 e0 fd ff ff 	mov    %rsi,-0x220(%rbp)
  8030d3:	48 8b 85 e8 fd ff ff 	mov    -0x218(%rbp),%rax
  8030da:	be 00 00 00 00       	mov    $0x0,%esi
  8030df:	48 89 c7             	mov    %rax,%rdi
  8030e2:	48 b8 58 2c 80 00 00 	movabs $0x802c58,%rax
  8030e9:	00 00 00 
  8030ec:	ff d0                	callq  *%rax
  8030ee:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8030f1:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8030f5:	79 28                	jns    80311f <copy+0x65>
  8030f7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8030fa:	89 c6                	mov    %eax,%esi
  8030fc:	48 bf ac 4e 80 00 00 	movabs $0x804eac,%rdi
  803103:	00 00 00 
  803106:	b8 00 00 00 00       	mov    $0x0,%eax
  80310b:	48 ba a8 08 80 00 00 	movabs $0x8008a8,%rdx
  803112:	00 00 00 
  803115:	ff d2                	callq  *%rdx
  803117:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80311a:	e9 74 01 00 00       	jmpq   803293 <copy+0x1d9>
  80311f:	48 8b 85 e0 fd ff ff 	mov    -0x220(%rbp),%rax
  803126:	be 01 01 00 00       	mov    $0x101,%esi
  80312b:	48 89 c7             	mov    %rax,%rdi
  80312e:	48 b8 58 2c 80 00 00 	movabs $0x802c58,%rax
  803135:	00 00 00 
  803138:	ff d0                	callq  *%rax
  80313a:	89 45 f8             	mov    %eax,-0x8(%rbp)
  80313d:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  803141:	79 39                	jns    80317c <copy+0xc2>
  803143:	8b 45 f8             	mov    -0x8(%rbp),%eax
  803146:	89 c6                	mov    %eax,%esi
  803148:	48 bf c2 4e 80 00 00 	movabs $0x804ec2,%rdi
  80314f:	00 00 00 
  803152:	b8 00 00 00 00       	mov    $0x0,%eax
  803157:	48 ba a8 08 80 00 00 	movabs $0x8008a8,%rdx
  80315e:	00 00 00 
  803161:	ff d2                	callq  *%rdx
  803163:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803166:	89 c7                	mov    %eax,%edi
  803168:	48 b8 60 25 80 00 00 	movabs $0x802560,%rax
  80316f:	00 00 00 
  803172:	ff d0                	callq  *%rax
  803174:	8b 45 f8             	mov    -0x8(%rbp),%eax
  803177:	e9 17 01 00 00       	jmpq   803293 <copy+0x1d9>
  80317c:	eb 74                	jmp    8031f2 <copy+0x138>
  80317e:	8b 45 f4             	mov    -0xc(%rbp),%eax
  803181:	48 63 d0             	movslq %eax,%rdx
  803184:	48 8d 8d f0 fd ff ff 	lea    -0x210(%rbp),%rcx
  80318b:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80318e:	48 89 ce             	mov    %rcx,%rsi
  803191:	89 c7                	mov    %eax,%edi
  803193:	48 b8 cc 28 80 00 00 	movabs $0x8028cc,%rax
  80319a:	00 00 00 
  80319d:	ff d0                	callq  *%rax
  80319f:	89 45 f0             	mov    %eax,-0x10(%rbp)
  8031a2:	83 7d f0 00          	cmpl   $0x0,-0x10(%rbp)
  8031a6:	79 4a                	jns    8031f2 <copy+0x138>
  8031a8:	8b 45 f0             	mov    -0x10(%rbp),%eax
  8031ab:	89 c6                	mov    %eax,%esi
  8031ad:	48 bf dc 4e 80 00 00 	movabs $0x804edc,%rdi
  8031b4:	00 00 00 
  8031b7:	b8 00 00 00 00       	mov    $0x0,%eax
  8031bc:	48 ba a8 08 80 00 00 	movabs $0x8008a8,%rdx
  8031c3:	00 00 00 
  8031c6:	ff d2                	callq  *%rdx
  8031c8:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8031cb:	89 c7                	mov    %eax,%edi
  8031cd:	48 b8 60 25 80 00 00 	movabs $0x802560,%rax
  8031d4:	00 00 00 
  8031d7:	ff d0                	callq  *%rax
  8031d9:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8031dc:	89 c7                	mov    %eax,%edi
  8031de:	48 b8 60 25 80 00 00 	movabs $0x802560,%rax
  8031e5:	00 00 00 
  8031e8:	ff d0                	callq  *%rax
  8031ea:	8b 45 f0             	mov    -0x10(%rbp),%eax
  8031ed:	e9 a1 00 00 00       	jmpq   803293 <copy+0x1d9>
  8031f2:	48 8d 8d f0 fd ff ff 	lea    -0x210(%rbp),%rcx
  8031f9:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8031fc:	ba 00 02 00 00       	mov    $0x200,%edx
  803201:	48 89 ce             	mov    %rcx,%rsi
  803204:	89 c7                	mov    %eax,%edi
  803206:	48 b8 82 27 80 00 00 	movabs $0x802782,%rax
  80320d:	00 00 00 
  803210:	ff d0                	callq  *%rax
  803212:	89 45 f4             	mov    %eax,-0xc(%rbp)
  803215:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  803219:	0f 8f 5f ff ff ff    	jg     80317e <copy+0xc4>
  80321f:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  803223:	79 47                	jns    80326c <copy+0x1b2>
  803225:	8b 45 f4             	mov    -0xc(%rbp),%eax
  803228:	89 c6                	mov    %eax,%esi
  80322a:	48 bf ef 4e 80 00 00 	movabs $0x804eef,%rdi
  803231:	00 00 00 
  803234:	b8 00 00 00 00       	mov    $0x0,%eax
  803239:	48 ba a8 08 80 00 00 	movabs $0x8008a8,%rdx
  803240:	00 00 00 
  803243:	ff d2                	callq  *%rdx
  803245:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803248:	89 c7                	mov    %eax,%edi
  80324a:	48 b8 60 25 80 00 00 	movabs $0x802560,%rax
  803251:	00 00 00 
  803254:	ff d0                	callq  *%rax
  803256:	8b 45 f8             	mov    -0x8(%rbp),%eax
  803259:	89 c7                	mov    %eax,%edi
  80325b:	48 b8 60 25 80 00 00 	movabs $0x802560,%rax
  803262:	00 00 00 
  803265:	ff d0                	callq  *%rax
  803267:	8b 45 f4             	mov    -0xc(%rbp),%eax
  80326a:	eb 27                	jmp    803293 <copy+0x1d9>
  80326c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80326f:	89 c7                	mov    %eax,%edi
  803271:	48 b8 60 25 80 00 00 	movabs $0x802560,%rax
  803278:	00 00 00 
  80327b:	ff d0                	callq  *%rax
  80327d:	8b 45 f8             	mov    -0x8(%rbp),%eax
  803280:	89 c7                	mov    %eax,%edi
  803282:	48 b8 60 25 80 00 00 	movabs $0x802560,%rax
  803289:	00 00 00 
  80328c:	ff d0                	callq  *%rax
  80328e:	b8 00 00 00 00       	mov    $0x0,%eax
  803293:	c9                   	leaveq 
  803294:	c3                   	retq   

0000000000803295 <fd2sockid>:
  803295:	55                   	push   %rbp
  803296:	48 89 e5             	mov    %rsp,%rbp
  803299:	48 83 ec 20          	sub    $0x20,%rsp
  80329d:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8032a0:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  8032a4:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8032a7:	48 89 d6             	mov    %rdx,%rsi
  8032aa:	89 c7                	mov    %eax,%edi
  8032ac:	48 b8 50 23 80 00 00 	movabs $0x802350,%rax
  8032b3:	00 00 00 
  8032b6:	ff d0                	callq  *%rax
  8032b8:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8032bb:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8032bf:	79 05                	jns    8032c6 <fd2sockid+0x31>
  8032c1:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8032c4:	eb 24                	jmp    8032ea <fd2sockid+0x55>
  8032c6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8032ca:	8b 10                	mov    (%rax),%edx
  8032cc:	48 b8 a0 60 80 00 00 	movabs $0x8060a0,%rax
  8032d3:	00 00 00 
  8032d6:	8b 00                	mov    (%rax),%eax
  8032d8:	39 c2                	cmp    %eax,%edx
  8032da:	74 07                	je     8032e3 <fd2sockid+0x4e>
  8032dc:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  8032e1:	eb 07                	jmp    8032ea <fd2sockid+0x55>
  8032e3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8032e7:	8b 40 0c             	mov    0xc(%rax),%eax
  8032ea:	c9                   	leaveq 
  8032eb:	c3                   	retq   

00000000008032ec <alloc_sockfd>:
  8032ec:	55                   	push   %rbp
  8032ed:	48 89 e5             	mov    %rsp,%rbp
  8032f0:	48 83 ec 20          	sub    $0x20,%rsp
  8032f4:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8032f7:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  8032fb:	48 89 c7             	mov    %rax,%rdi
  8032fe:	48 b8 b8 22 80 00 00 	movabs $0x8022b8,%rax
  803305:	00 00 00 
  803308:	ff d0                	callq  *%rax
  80330a:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80330d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803311:	78 26                	js     803339 <alloc_sockfd+0x4d>
  803313:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803317:	ba 07 04 00 00       	mov    $0x407,%edx
  80331c:	48 89 c6             	mov    %rax,%rsi
  80331f:	bf 00 00 00 00       	mov    $0x0,%edi
  803324:	48 b8 8c 1d 80 00 00 	movabs $0x801d8c,%rax
  80332b:	00 00 00 
  80332e:	ff d0                	callq  *%rax
  803330:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803333:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803337:	79 16                	jns    80334f <alloc_sockfd+0x63>
  803339:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80333c:	89 c7                	mov    %eax,%edi
  80333e:	48 b8 f9 37 80 00 00 	movabs $0x8037f9,%rax
  803345:	00 00 00 
  803348:	ff d0                	callq  *%rax
  80334a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80334d:	eb 3a                	jmp    803389 <alloc_sockfd+0x9d>
  80334f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803353:	48 ba a0 60 80 00 00 	movabs $0x8060a0,%rdx
  80335a:	00 00 00 
  80335d:	8b 12                	mov    (%rdx),%edx
  80335f:	89 10                	mov    %edx,(%rax)
  803361:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803365:	c7 40 08 02 00 00 00 	movl   $0x2,0x8(%rax)
  80336c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803370:	8b 55 ec             	mov    -0x14(%rbp),%edx
  803373:	89 50 0c             	mov    %edx,0xc(%rax)
  803376:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80337a:	48 89 c7             	mov    %rax,%rdi
  80337d:	48 b8 6a 22 80 00 00 	movabs $0x80226a,%rax
  803384:	00 00 00 
  803387:	ff d0                	callq  *%rax
  803389:	c9                   	leaveq 
  80338a:	c3                   	retq   

000000000080338b <accept>:
  80338b:	55                   	push   %rbp
  80338c:	48 89 e5             	mov    %rsp,%rbp
  80338f:	48 83 ec 30          	sub    $0x30,%rsp
  803393:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803396:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80339a:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80339e:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8033a1:	89 c7                	mov    %eax,%edi
  8033a3:	48 b8 95 32 80 00 00 	movabs $0x803295,%rax
  8033aa:	00 00 00 
  8033ad:	ff d0                	callq  *%rax
  8033af:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8033b2:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8033b6:	79 05                	jns    8033bd <accept+0x32>
  8033b8:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8033bb:	eb 3b                	jmp    8033f8 <accept+0x6d>
  8033bd:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8033c1:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  8033c5:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8033c8:	48 89 ce             	mov    %rcx,%rsi
  8033cb:	89 c7                	mov    %eax,%edi
  8033cd:	48 b8 d6 36 80 00 00 	movabs $0x8036d6,%rax
  8033d4:	00 00 00 
  8033d7:	ff d0                	callq  *%rax
  8033d9:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8033dc:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8033e0:	79 05                	jns    8033e7 <accept+0x5c>
  8033e2:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8033e5:	eb 11                	jmp    8033f8 <accept+0x6d>
  8033e7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8033ea:	89 c7                	mov    %eax,%edi
  8033ec:	48 b8 ec 32 80 00 00 	movabs $0x8032ec,%rax
  8033f3:	00 00 00 
  8033f6:	ff d0                	callq  *%rax
  8033f8:	c9                   	leaveq 
  8033f9:	c3                   	retq   

00000000008033fa <bind>:
  8033fa:	55                   	push   %rbp
  8033fb:	48 89 e5             	mov    %rsp,%rbp
  8033fe:	48 83 ec 20          	sub    $0x20,%rsp
  803402:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803405:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  803409:	89 55 e8             	mov    %edx,-0x18(%rbp)
  80340c:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80340f:	89 c7                	mov    %eax,%edi
  803411:	48 b8 95 32 80 00 00 	movabs $0x803295,%rax
  803418:	00 00 00 
  80341b:	ff d0                	callq  *%rax
  80341d:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803420:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803424:	79 05                	jns    80342b <bind+0x31>
  803426:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803429:	eb 1b                	jmp    803446 <bind+0x4c>
  80342b:	8b 55 e8             	mov    -0x18(%rbp),%edx
  80342e:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  803432:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803435:	48 89 ce             	mov    %rcx,%rsi
  803438:	89 c7                	mov    %eax,%edi
  80343a:	48 b8 55 37 80 00 00 	movabs $0x803755,%rax
  803441:	00 00 00 
  803444:	ff d0                	callq  *%rax
  803446:	c9                   	leaveq 
  803447:	c3                   	retq   

0000000000803448 <shutdown>:
  803448:	55                   	push   %rbp
  803449:	48 89 e5             	mov    %rsp,%rbp
  80344c:	48 83 ec 20          	sub    $0x20,%rsp
  803450:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803453:	89 75 e8             	mov    %esi,-0x18(%rbp)
  803456:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803459:	89 c7                	mov    %eax,%edi
  80345b:	48 b8 95 32 80 00 00 	movabs $0x803295,%rax
  803462:	00 00 00 
  803465:	ff d0                	callq  *%rax
  803467:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80346a:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80346e:	79 05                	jns    803475 <shutdown+0x2d>
  803470:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803473:	eb 16                	jmp    80348b <shutdown+0x43>
  803475:	8b 55 e8             	mov    -0x18(%rbp),%edx
  803478:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80347b:	89 d6                	mov    %edx,%esi
  80347d:	89 c7                	mov    %eax,%edi
  80347f:	48 b8 b9 37 80 00 00 	movabs $0x8037b9,%rax
  803486:	00 00 00 
  803489:	ff d0                	callq  *%rax
  80348b:	c9                   	leaveq 
  80348c:	c3                   	retq   

000000000080348d <devsock_close>:
  80348d:	55                   	push   %rbp
  80348e:	48 89 e5             	mov    %rsp,%rbp
  803491:	48 83 ec 10          	sub    $0x10,%rsp
  803495:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  803499:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80349d:	48 89 c7             	mov    %rax,%rdi
  8034a0:	48 b8 8f 46 80 00 00 	movabs $0x80468f,%rax
  8034a7:	00 00 00 
  8034aa:	ff d0                	callq  *%rax
  8034ac:	83 f8 01             	cmp    $0x1,%eax
  8034af:	75 17                	jne    8034c8 <devsock_close+0x3b>
  8034b1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8034b5:	8b 40 0c             	mov    0xc(%rax),%eax
  8034b8:	89 c7                	mov    %eax,%edi
  8034ba:	48 b8 f9 37 80 00 00 	movabs $0x8037f9,%rax
  8034c1:	00 00 00 
  8034c4:	ff d0                	callq  *%rax
  8034c6:	eb 05                	jmp    8034cd <devsock_close+0x40>
  8034c8:	b8 00 00 00 00       	mov    $0x0,%eax
  8034cd:	c9                   	leaveq 
  8034ce:	c3                   	retq   

00000000008034cf <connect>:
  8034cf:	55                   	push   %rbp
  8034d0:	48 89 e5             	mov    %rsp,%rbp
  8034d3:	48 83 ec 20          	sub    $0x20,%rsp
  8034d7:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8034da:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8034de:	89 55 e8             	mov    %edx,-0x18(%rbp)
  8034e1:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8034e4:	89 c7                	mov    %eax,%edi
  8034e6:	48 b8 95 32 80 00 00 	movabs $0x803295,%rax
  8034ed:	00 00 00 
  8034f0:	ff d0                	callq  *%rax
  8034f2:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8034f5:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8034f9:	79 05                	jns    803500 <connect+0x31>
  8034fb:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8034fe:	eb 1b                	jmp    80351b <connect+0x4c>
  803500:	8b 55 e8             	mov    -0x18(%rbp),%edx
  803503:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  803507:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80350a:	48 89 ce             	mov    %rcx,%rsi
  80350d:	89 c7                	mov    %eax,%edi
  80350f:	48 b8 26 38 80 00 00 	movabs $0x803826,%rax
  803516:	00 00 00 
  803519:	ff d0                	callq  *%rax
  80351b:	c9                   	leaveq 
  80351c:	c3                   	retq   

000000000080351d <listen>:
  80351d:	55                   	push   %rbp
  80351e:	48 89 e5             	mov    %rsp,%rbp
  803521:	48 83 ec 20          	sub    $0x20,%rsp
  803525:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803528:	89 75 e8             	mov    %esi,-0x18(%rbp)
  80352b:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80352e:	89 c7                	mov    %eax,%edi
  803530:	48 b8 95 32 80 00 00 	movabs $0x803295,%rax
  803537:	00 00 00 
  80353a:	ff d0                	callq  *%rax
  80353c:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80353f:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803543:	79 05                	jns    80354a <listen+0x2d>
  803545:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803548:	eb 16                	jmp    803560 <listen+0x43>
  80354a:	8b 55 e8             	mov    -0x18(%rbp),%edx
  80354d:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803550:	89 d6                	mov    %edx,%esi
  803552:	89 c7                	mov    %eax,%edi
  803554:	48 b8 8a 38 80 00 00 	movabs $0x80388a,%rax
  80355b:	00 00 00 
  80355e:	ff d0                	callq  *%rax
  803560:	c9                   	leaveq 
  803561:	c3                   	retq   

0000000000803562 <devsock_read>:
  803562:	55                   	push   %rbp
  803563:	48 89 e5             	mov    %rsp,%rbp
  803566:	48 83 ec 20          	sub    $0x20,%rsp
  80356a:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80356e:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  803572:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  803576:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80357a:	89 c2                	mov    %eax,%edx
  80357c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803580:	8b 40 0c             	mov    0xc(%rax),%eax
  803583:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
  803587:	b9 00 00 00 00       	mov    $0x0,%ecx
  80358c:	89 c7                	mov    %eax,%edi
  80358e:	48 b8 ca 38 80 00 00 	movabs $0x8038ca,%rax
  803595:	00 00 00 
  803598:	ff d0                	callq  *%rax
  80359a:	c9                   	leaveq 
  80359b:	c3                   	retq   

000000000080359c <devsock_write>:
  80359c:	55                   	push   %rbp
  80359d:	48 89 e5             	mov    %rsp,%rbp
  8035a0:	48 83 ec 20          	sub    $0x20,%rsp
  8035a4:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8035a8:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8035ac:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8035b0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8035b4:	89 c2                	mov    %eax,%edx
  8035b6:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8035ba:	8b 40 0c             	mov    0xc(%rax),%eax
  8035bd:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
  8035c1:	b9 00 00 00 00       	mov    $0x0,%ecx
  8035c6:	89 c7                	mov    %eax,%edi
  8035c8:	48 b8 96 39 80 00 00 	movabs $0x803996,%rax
  8035cf:	00 00 00 
  8035d2:	ff d0                	callq  *%rax
  8035d4:	c9                   	leaveq 
  8035d5:	c3                   	retq   

00000000008035d6 <devsock_stat>:
  8035d6:	55                   	push   %rbp
  8035d7:	48 89 e5             	mov    %rsp,%rbp
  8035da:	48 83 ec 10          	sub    $0x10,%rsp
  8035de:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8035e2:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8035e6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8035ea:	48 be 0a 4f 80 00 00 	movabs $0x804f0a,%rsi
  8035f1:	00 00 00 
  8035f4:	48 89 c7             	mov    %rax,%rdi
  8035f7:	48 b8 5d 14 80 00 00 	movabs $0x80145d,%rax
  8035fe:	00 00 00 
  803601:	ff d0                	callq  *%rax
  803603:	b8 00 00 00 00       	mov    $0x0,%eax
  803608:	c9                   	leaveq 
  803609:	c3                   	retq   

000000000080360a <socket>:
  80360a:	55                   	push   %rbp
  80360b:	48 89 e5             	mov    %rsp,%rbp
  80360e:	48 83 ec 20          	sub    $0x20,%rsp
  803612:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803615:	89 75 e8             	mov    %esi,-0x18(%rbp)
  803618:	89 55 e4             	mov    %edx,-0x1c(%rbp)
  80361b:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  80361e:	8b 4d e8             	mov    -0x18(%rbp),%ecx
  803621:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803624:	89 ce                	mov    %ecx,%esi
  803626:	89 c7                	mov    %eax,%edi
  803628:	48 b8 4e 3a 80 00 00 	movabs $0x803a4e,%rax
  80362f:	00 00 00 
  803632:	ff d0                	callq  *%rax
  803634:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803637:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80363b:	79 05                	jns    803642 <socket+0x38>
  80363d:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803640:	eb 11                	jmp    803653 <socket+0x49>
  803642:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803645:	89 c7                	mov    %eax,%edi
  803647:	48 b8 ec 32 80 00 00 	movabs $0x8032ec,%rax
  80364e:	00 00 00 
  803651:	ff d0                	callq  *%rax
  803653:	c9                   	leaveq 
  803654:	c3                   	retq   

0000000000803655 <nsipc>:
  803655:	55                   	push   %rbp
  803656:	48 89 e5             	mov    %rsp,%rbp
  803659:	48 83 ec 10          	sub    $0x10,%rsp
  80365d:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803660:	48 b8 04 70 80 00 00 	movabs $0x807004,%rax
  803667:	00 00 00 
  80366a:	8b 00                	mov    (%rax),%eax
  80366c:	85 c0                	test   %eax,%eax
  80366e:	75 1d                	jne    80368d <nsipc+0x38>
  803670:	bf 02 00 00 00       	mov    $0x2,%edi
  803675:	48 b8 1d 46 80 00 00 	movabs $0x80461d,%rax
  80367c:	00 00 00 
  80367f:	ff d0                	callq  *%rax
  803681:	48 ba 04 70 80 00 00 	movabs $0x807004,%rdx
  803688:	00 00 00 
  80368b:	89 02                	mov    %eax,(%rdx)
  80368d:	48 b8 04 70 80 00 00 	movabs $0x807004,%rax
  803694:	00 00 00 
  803697:	8b 00                	mov    (%rax),%eax
  803699:	8b 75 fc             	mov    -0x4(%rbp),%esi
  80369c:	b9 07 00 00 00       	mov    $0x7,%ecx
  8036a1:	48 ba 00 a0 80 00 00 	movabs $0x80a000,%rdx
  8036a8:	00 00 00 
  8036ab:	89 c7                	mov    %eax,%edi
  8036ad:	48 b8 87 45 80 00 00 	movabs $0x804587,%rax
  8036b4:	00 00 00 
  8036b7:	ff d0                	callq  *%rax
  8036b9:	ba 00 00 00 00       	mov    $0x0,%edx
  8036be:	be 00 00 00 00       	mov    $0x0,%esi
  8036c3:	bf 00 00 00 00       	mov    $0x0,%edi
  8036c8:	48 b8 c6 44 80 00 00 	movabs $0x8044c6,%rax
  8036cf:	00 00 00 
  8036d2:	ff d0                	callq  *%rax
  8036d4:	c9                   	leaveq 
  8036d5:	c3                   	retq   

00000000008036d6 <nsipc_accept>:
  8036d6:	55                   	push   %rbp
  8036d7:	48 89 e5             	mov    %rsp,%rbp
  8036da:	48 83 ec 30          	sub    $0x30,%rsp
  8036de:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8036e1:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8036e5:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8036e9:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8036f0:	00 00 00 
  8036f3:	8b 55 ec             	mov    -0x14(%rbp),%edx
  8036f6:	89 10                	mov    %edx,(%rax)
  8036f8:	bf 01 00 00 00       	mov    $0x1,%edi
  8036fd:	48 b8 55 36 80 00 00 	movabs $0x803655,%rax
  803704:	00 00 00 
  803707:	ff d0                	callq  *%rax
  803709:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80370c:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803710:	78 3e                	js     803750 <nsipc_accept+0x7a>
  803712:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803719:	00 00 00 
  80371c:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  803720:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803724:	8b 40 10             	mov    0x10(%rax),%eax
  803727:	89 c2                	mov    %eax,%edx
  803729:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
  80372d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803731:	48 89 ce             	mov    %rcx,%rsi
  803734:	48 89 c7             	mov    %rax,%rdi
  803737:	48 b8 81 17 80 00 00 	movabs $0x801781,%rax
  80373e:	00 00 00 
  803741:	ff d0                	callq  *%rax
  803743:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803747:	8b 50 10             	mov    0x10(%rax),%edx
  80374a:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80374e:	89 10                	mov    %edx,(%rax)
  803750:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803753:	c9                   	leaveq 
  803754:	c3                   	retq   

0000000000803755 <nsipc_bind>:
  803755:	55                   	push   %rbp
  803756:	48 89 e5             	mov    %rsp,%rbp
  803759:	48 83 ec 10          	sub    $0x10,%rsp
  80375d:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803760:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  803764:	89 55 f8             	mov    %edx,-0x8(%rbp)
  803767:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80376e:	00 00 00 
  803771:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803774:	89 10                	mov    %edx,(%rax)
  803776:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803779:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80377d:	48 89 c6             	mov    %rax,%rsi
  803780:	48 bf 04 a0 80 00 00 	movabs $0x80a004,%rdi
  803787:	00 00 00 
  80378a:	48 b8 81 17 80 00 00 	movabs $0x801781,%rax
  803791:	00 00 00 
  803794:	ff d0                	callq  *%rax
  803796:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80379d:	00 00 00 
  8037a0:	8b 55 f8             	mov    -0x8(%rbp),%edx
  8037a3:	89 50 14             	mov    %edx,0x14(%rax)
  8037a6:	bf 02 00 00 00       	mov    $0x2,%edi
  8037ab:	48 b8 55 36 80 00 00 	movabs $0x803655,%rax
  8037b2:	00 00 00 
  8037b5:	ff d0                	callq  *%rax
  8037b7:	c9                   	leaveq 
  8037b8:	c3                   	retq   

00000000008037b9 <nsipc_shutdown>:
  8037b9:	55                   	push   %rbp
  8037ba:	48 89 e5             	mov    %rsp,%rbp
  8037bd:	48 83 ec 10          	sub    $0x10,%rsp
  8037c1:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8037c4:	89 75 f8             	mov    %esi,-0x8(%rbp)
  8037c7:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8037ce:	00 00 00 
  8037d1:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8037d4:	89 10                	mov    %edx,(%rax)
  8037d6:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8037dd:	00 00 00 
  8037e0:	8b 55 f8             	mov    -0x8(%rbp),%edx
  8037e3:	89 50 04             	mov    %edx,0x4(%rax)
  8037e6:	bf 03 00 00 00       	mov    $0x3,%edi
  8037eb:	48 b8 55 36 80 00 00 	movabs $0x803655,%rax
  8037f2:	00 00 00 
  8037f5:	ff d0                	callq  *%rax
  8037f7:	c9                   	leaveq 
  8037f8:	c3                   	retq   

00000000008037f9 <nsipc_close>:
  8037f9:	55                   	push   %rbp
  8037fa:	48 89 e5             	mov    %rsp,%rbp
  8037fd:	48 83 ec 10          	sub    $0x10,%rsp
  803801:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803804:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80380b:	00 00 00 
  80380e:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803811:	89 10                	mov    %edx,(%rax)
  803813:	bf 04 00 00 00       	mov    $0x4,%edi
  803818:	48 b8 55 36 80 00 00 	movabs $0x803655,%rax
  80381f:	00 00 00 
  803822:	ff d0                	callq  *%rax
  803824:	c9                   	leaveq 
  803825:	c3                   	retq   

0000000000803826 <nsipc_connect>:
  803826:	55                   	push   %rbp
  803827:	48 89 e5             	mov    %rsp,%rbp
  80382a:	48 83 ec 10          	sub    $0x10,%rsp
  80382e:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803831:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  803835:	89 55 f8             	mov    %edx,-0x8(%rbp)
  803838:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80383f:	00 00 00 
  803842:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803845:	89 10                	mov    %edx,(%rax)
  803847:	8b 55 f8             	mov    -0x8(%rbp),%edx
  80384a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80384e:	48 89 c6             	mov    %rax,%rsi
  803851:	48 bf 04 a0 80 00 00 	movabs $0x80a004,%rdi
  803858:	00 00 00 
  80385b:	48 b8 81 17 80 00 00 	movabs $0x801781,%rax
  803862:	00 00 00 
  803865:	ff d0                	callq  *%rax
  803867:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80386e:	00 00 00 
  803871:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803874:	89 50 14             	mov    %edx,0x14(%rax)
  803877:	bf 05 00 00 00       	mov    $0x5,%edi
  80387c:	48 b8 55 36 80 00 00 	movabs $0x803655,%rax
  803883:	00 00 00 
  803886:	ff d0                	callq  *%rax
  803888:	c9                   	leaveq 
  803889:	c3                   	retq   

000000000080388a <nsipc_listen>:
  80388a:	55                   	push   %rbp
  80388b:	48 89 e5             	mov    %rsp,%rbp
  80388e:	48 83 ec 10          	sub    $0x10,%rsp
  803892:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803895:	89 75 f8             	mov    %esi,-0x8(%rbp)
  803898:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80389f:	00 00 00 
  8038a2:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8038a5:	89 10                	mov    %edx,(%rax)
  8038a7:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8038ae:	00 00 00 
  8038b1:	8b 55 f8             	mov    -0x8(%rbp),%edx
  8038b4:	89 50 04             	mov    %edx,0x4(%rax)
  8038b7:	bf 06 00 00 00       	mov    $0x6,%edi
  8038bc:	48 b8 55 36 80 00 00 	movabs $0x803655,%rax
  8038c3:	00 00 00 
  8038c6:	ff d0                	callq  *%rax
  8038c8:	c9                   	leaveq 
  8038c9:	c3                   	retq   

00000000008038ca <nsipc_recv>:
  8038ca:	55                   	push   %rbp
  8038cb:	48 89 e5             	mov    %rsp,%rbp
  8038ce:	48 83 ec 30          	sub    $0x30,%rsp
  8038d2:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8038d5:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8038d9:	89 55 e8             	mov    %edx,-0x18(%rbp)
  8038dc:	89 4d dc             	mov    %ecx,-0x24(%rbp)
  8038df:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8038e6:	00 00 00 
  8038e9:	8b 55 ec             	mov    -0x14(%rbp),%edx
  8038ec:	89 10                	mov    %edx,(%rax)
  8038ee:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8038f5:	00 00 00 
  8038f8:	8b 55 e8             	mov    -0x18(%rbp),%edx
  8038fb:	89 50 04             	mov    %edx,0x4(%rax)
  8038fe:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803905:	00 00 00 
  803908:	8b 55 dc             	mov    -0x24(%rbp),%edx
  80390b:	89 50 08             	mov    %edx,0x8(%rax)
  80390e:	bf 07 00 00 00       	mov    $0x7,%edi
  803913:	48 b8 55 36 80 00 00 	movabs $0x803655,%rax
  80391a:	00 00 00 
  80391d:	ff d0                	callq  *%rax
  80391f:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803922:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803926:	78 69                	js     803991 <nsipc_recv+0xc7>
  803928:	81 7d fc 3f 06 00 00 	cmpl   $0x63f,-0x4(%rbp)
  80392f:	7f 08                	jg     803939 <nsipc_recv+0x6f>
  803931:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803934:	3b 45 e8             	cmp    -0x18(%rbp),%eax
  803937:	7e 35                	jle    80396e <nsipc_recv+0xa4>
  803939:	48 b9 11 4f 80 00 00 	movabs $0x804f11,%rcx
  803940:	00 00 00 
  803943:	48 ba 26 4f 80 00 00 	movabs $0x804f26,%rdx
  80394a:	00 00 00 
  80394d:	be 62 00 00 00       	mov    $0x62,%esi
  803952:	48 bf 3b 4f 80 00 00 	movabs $0x804f3b,%rdi
  803959:	00 00 00 
  80395c:	b8 00 00 00 00       	mov    $0x0,%eax
  803961:	49 b8 b2 43 80 00 00 	movabs $0x8043b2,%r8
  803968:	00 00 00 
  80396b:	41 ff d0             	callq  *%r8
  80396e:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803971:	48 63 d0             	movslq %eax,%rdx
  803974:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803978:	48 be 00 a0 80 00 00 	movabs $0x80a000,%rsi
  80397f:	00 00 00 
  803982:	48 89 c7             	mov    %rax,%rdi
  803985:	48 b8 81 17 80 00 00 	movabs $0x801781,%rax
  80398c:	00 00 00 
  80398f:	ff d0                	callq  *%rax
  803991:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803994:	c9                   	leaveq 
  803995:	c3                   	retq   

0000000000803996 <nsipc_send>:
  803996:	55                   	push   %rbp
  803997:	48 89 e5             	mov    %rsp,%rbp
  80399a:	48 83 ec 20          	sub    $0x20,%rsp
  80399e:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8039a1:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8039a5:	89 55 f8             	mov    %edx,-0x8(%rbp)
  8039a8:	89 4d ec             	mov    %ecx,-0x14(%rbp)
  8039ab:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8039b2:	00 00 00 
  8039b5:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8039b8:	89 10                	mov    %edx,(%rax)
  8039ba:	81 7d f8 3f 06 00 00 	cmpl   $0x63f,-0x8(%rbp)
  8039c1:	7e 35                	jle    8039f8 <nsipc_send+0x62>
  8039c3:	48 b9 4a 4f 80 00 00 	movabs $0x804f4a,%rcx
  8039ca:	00 00 00 
  8039cd:	48 ba 26 4f 80 00 00 	movabs $0x804f26,%rdx
  8039d4:	00 00 00 
  8039d7:	be 6d 00 00 00       	mov    $0x6d,%esi
  8039dc:	48 bf 3b 4f 80 00 00 	movabs $0x804f3b,%rdi
  8039e3:	00 00 00 
  8039e6:	b8 00 00 00 00       	mov    $0x0,%eax
  8039eb:	49 b8 b2 43 80 00 00 	movabs $0x8043b2,%r8
  8039f2:	00 00 00 
  8039f5:	41 ff d0             	callq  *%r8
  8039f8:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8039fb:	48 63 d0             	movslq %eax,%rdx
  8039fe:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803a02:	48 89 c6             	mov    %rax,%rsi
  803a05:	48 bf 0c a0 80 00 00 	movabs $0x80a00c,%rdi
  803a0c:	00 00 00 
  803a0f:	48 b8 81 17 80 00 00 	movabs $0x801781,%rax
  803a16:	00 00 00 
  803a19:	ff d0                	callq  *%rax
  803a1b:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803a22:	00 00 00 
  803a25:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803a28:	89 50 04             	mov    %edx,0x4(%rax)
  803a2b:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803a32:	00 00 00 
  803a35:	8b 55 ec             	mov    -0x14(%rbp),%edx
  803a38:	89 50 08             	mov    %edx,0x8(%rax)
  803a3b:	bf 08 00 00 00       	mov    $0x8,%edi
  803a40:	48 b8 55 36 80 00 00 	movabs $0x803655,%rax
  803a47:	00 00 00 
  803a4a:	ff d0                	callq  *%rax
  803a4c:	c9                   	leaveq 
  803a4d:	c3                   	retq   

0000000000803a4e <nsipc_socket>:
  803a4e:	55                   	push   %rbp
  803a4f:	48 89 e5             	mov    %rsp,%rbp
  803a52:	48 83 ec 10          	sub    $0x10,%rsp
  803a56:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803a59:	89 75 f8             	mov    %esi,-0x8(%rbp)
  803a5c:	89 55 f4             	mov    %edx,-0xc(%rbp)
  803a5f:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803a66:	00 00 00 
  803a69:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803a6c:	89 10                	mov    %edx,(%rax)
  803a6e:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803a75:	00 00 00 
  803a78:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803a7b:	89 50 04             	mov    %edx,0x4(%rax)
  803a7e:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803a85:	00 00 00 
  803a88:	8b 55 f4             	mov    -0xc(%rbp),%edx
  803a8b:	89 50 08             	mov    %edx,0x8(%rax)
  803a8e:	bf 09 00 00 00       	mov    $0x9,%edi
  803a93:	48 b8 55 36 80 00 00 	movabs $0x803655,%rax
  803a9a:	00 00 00 
  803a9d:	ff d0                	callq  *%rax
  803a9f:	c9                   	leaveq 
  803aa0:	c3                   	retq   

0000000000803aa1 <pipe>:
  803aa1:	55                   	push   %rbp
  803aa2:	48 89 e5             	mov    %rsp,%rbp
  803aa5:	53                   	push   %rbx
  803aa6:	48 83 ec 38          	sub    $0x38,%rsp
  803aaa:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  803aae:	48 8d 45 d8          	lea    -0x28(%rbp),%rax
  803ab2:	48 89 c7             	mov    %rax,%rdi
  803ab5:	48 b8 b8 22 80 00 00 	movabs $0x8022b8,%rax
  803abc:	00 00 00 
  803abf:	ff d0                	callq  *%rax
  803ac1:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803ac4:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803ac8:	0f 88 bf 01 00 00    	js     803c8d <pipe+0x1ec>
  803ace:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803ad2:	ba 07 04 00 00       	mov    $0x407,%edx
  803ad7:	48 89 c6             	mov    %rax,%rsi
  803ada:	bf 00 00 00 00       	mov    $0x0,%edi
  803adf:	48 b8 8c 1d 80 00 00 	movabs $0x801d8c,%rax
  803ae6:	00 00 00 
  803ae9:	ff d0                	callq  *%rax
  803aeb:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803aee:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803af2:	0f 88 95 01 00 00    	js     803c8d <pipe+0x1ec>
  803af8:	48 8d 45 d0          	lea    -0x30(%rbp),%rax
  803afc:	48 89 c7             	mov    %rax,%rdi
  803aff:	48 b8 b8 22 80 00 00 	movabs $0x8022b8,%rax
  803b06:	00 00 00 
  803b09:	ff d0                	callq  *%rax
  803b0b:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803b0e:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803b12:	0f 88 5d 01 00 00    	js     803c75 <pipe+0x1d4>
  803b18:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803b1c:	ba 07 04 00 00       	mov    $0x407,%edx
  803b21:	48 89 c6             	mov    %rax,%rsi
  803b24:	bf 00 00 00 00       	mov    $0x0,%edi
  803b29:	48 b8 8c 1d 80 00 00 	movabs $0x801d8c,%rax
  803b30:	00 00 00 
  803b33:	ff d0                	callq  *%rax
  803b35:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803b38:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803b3c:	0f 88 33 01 00 00    	js     803c75 <pipe+0x1d4>
  803b42:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803b46:	48 89 c7             	mov    %rax,%rdi
  803b49:	48 b8 8d 22 80 00 00 	movabs $0x80228d,%rax
  803b50:	00 00 00 
  803b53:	ff d0                	callq  *%rax
  803b55:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  803b59:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803b5d:	ba 07 04 00 00       	mov    $0x407,%edx
  803b62:	48 89 c6             	mov    %rax,%rsi
  803b65:	bf 00 00 00 00       	mov    $0x0,%edi
  803b6a:	48 b8 8c 1d 80 00 00 	movabs $0x801d8c,%rax
  803b71:	00 00 00 
  803b74:	ff d0                	callq  *%rax
  803b76:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803b79:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803b7d:	79 05                	jns    803b84 <pipe+0xe3>
  803b7f:	e9 d9 00 00 00       	jmpq   803c5d <pipe+0x1bc>
  803b84:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803b88:	48 89 c7             	mov    %rax,%rdi
  803b8b:	48 b8 8d 22 80 00 00 	movabs $0x80228d,%rax
  803b92:	00 00 00 
  803b95:	ff d0                	callq  *%rax
  803b97:	48 89 c2             	mov    %rax,%rdx
  803b9a:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803b9e:	41 b8 07 04 00 00    	mov    $0x407,%r8d
  803ba4:	48 89 d1             	mov    %rdx,%rcx
  803ba7:	ba 00 00 00 00       	mov    $0x0,%edx
  803bac:	48 89 c6             	mov    %rax,%rsi
  803baf:	bf 00 00 00 00       	mov    $0x0,%edi
  803bb4:	48 b8 dc 1d 80 00 00 	movabs $0x801ddc,%rax
  803bbb:	00 00 00 
  803bbe:	ff d0                	callq  *%rax
  803bc0:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803bc3:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803bc7:	79 1b                	jns    803be4 <pipe+0x143>
  803bc9:	90                   	nop
  803bca:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803bce:	48 89 c6             	mov    %rax,%rsi
  803bd1:	bf 00 00 00 00       	mov    $0x0,%edi
  803bd6:	48 b8 37 1e 80 00 00 	movabs $0x801e37,%rax
  803bdd:	00 00 00 
  803be0:	ff d0                	callq  *%rax
  803be2:	eb 79                	jmp    803c5d <pipe+0x1bc>
  803be4:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803be8:	48 ba e0 60 80 00 00 	movabs $0x8060e0,%rdx
  803bef:	00 00 00 
  803bf2:	8b 12                	mov    (%rdx),%edx
  803bf4:	89 10                	mov    %edx,(%rax)
  803bf6:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803bfa:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%rax)
  803c01:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803c05:	48 ba e0 60 80 00 00 	movabs $0x8060e0,%rdx
  803c0c:	00 00 00 
  803c0f:	8b 12                	mov    (%rdx),%edx
  803c11:	89 10                	mov    %edx,(%rax)
  803c13:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803c17:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%rax)
  803c1e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803c22:	48 89 c7             	mov    %rax,%rdi
  803c25:	48 b8 6a 22 80 00 00 	movabs $0x80226a,%rax
  803c2c:	00 00 00 
  803c2f:	ff d0                	callq  *%rax
  803c31:	89 c2                	mov    %eax,%edx
  803c33:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  803c37:	89 10                	mov    %edx,(%rax)
  803c39:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  803c3d:	48 8d 58 04          	lea    0x4(%rax),%rbx
  803c41:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803c45:	48 89 c7             	mov    %rax,%rdi
  803c48:	48 b8 6a 22 80 00 00 	movabs $0x80226a,%rax
  803c4f:	00 00 00 
  803c52:	ff d0                	callq  *%rax
  803c54:	89 03                	mov    %eax,(%rbx)
  803c56:	b8 00 00 00 00       	mov    $0x0,%eax
  803c5b:	eb 33                	jmp    803c90 <pipe+0x1ef>
  803c5d:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803c61:	48 89 c6             	mov    %rax,%rsi
  803c64:	bf 00 00 00 00       	mov    $0x0,%edi
  803c69:	48 b8 37 1e 80 00 00 	movabs $0x801e37,%rax
  803c70:	00 00 00 
  803c73:	ff d0                	callq  *%rax
  803c75:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803c79:	48 89 c6             	mov    %rax,%rsi
  803c7c:	bf 00 00 00 00       	mov    $0x0,%edi
  803c81:	48 b8 37 1e 80 00 00 	movabs $0x801e37,%rax
  803c88:	00 00 00 
  803c8b:	ff d0                	callq  *%rax
  803c8d:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803c90:	48 83 c4 38          	add    $0x38,%rsp
  803c94:	5b                   	pop    %rbx
  803c95:	5d                   	pop    %rbp
  803c96:	c3                   	retq   

0000000000803c97 <_pipeisclosed>:
  803c97:	55                   	push   %rbp
  803c98:	48 89 e5             	mov    %rsp,%rbp
  803c9b:	53                   	push   %rbx
  803c9c:	48 83 ec 28          	sub    $0x28,%rsp
  803ca0:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  803ca4:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  803ca8:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  803caf:	00 00 00 
  803cb2:	48 8b 00             	mov    (%rax),%rax
  803cb5:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  803cbb:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803cbe:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803cc2:	48 89 c7             	mov    %rax,%rdi
  803cc5:	48 b8 8f 46 80 00 00 	movabs $0x80468f,%rax
  803ccc:	00 00 00 
  803ccf:	ff d0                	callq  *%rax
  803cd1:	89 c3                	mov    %eax,%ebx
  803cd3:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803cd7:	48 89 c7             	mov    %rax,%rdi
  803cda:	48 b8 8f 46 80 00 00 	movabs $0x80468f,%rax
  803ce1:	00 00 00 
  803ce4:	ff d0                	callq  *%rax
  803ce6:	39 c3                	cmp    %eax,%ebx
  803ce8:	0f 94 c0             	sete   %al
  803ceb:	0f b6 c0             	movzbl %al,%eax
  803cee:	89 45 e8             	mov    %eax,-0x18(%rbp)
  803cf1:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  803cf8:	00 00 00 
  803cfb:	48 8b 00             	mov    (%rax),%rax
  803cfe:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  803d04:	89 45 e4             	mov    %eax,-0x1c(%rbp)
  803d07:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803d0a:	3b 45 e4             	cmp    -0x1c(%rbp),%eax
  803d0d:	75 05                	jne    803d14 <_pipeisclosed+0x7d>
  803d0f:	8b 45 e8             	mov    -0x18(%rbp),%eax
  803d12:	eb 4f                	jmp    803d63 <_pipeisclosed+0xcc>
  803d14:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803d17:	3b 45 e4             	cmp    -0x1c(%rbp),%eax
  803d1a:	74 42                	je     803d5e <_pipeisclosed+0xc7>
  803d1c:	83 7d e8 01          	cmpl   $0x1,-0x18(%rbp)
  803d20:	75 3c                	jne    803d5e <_pipeisclosed+0xc7>
  803d22:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  803d29:	00 00 00 
  803d2c:	48 8b 00             	mov    (%rax),%rax
  803d2f:	8b 90 d8 00 00 00    	mov    0xd8(%rax),%edx
  803d35:	8b 4d e8             	mov    -0x18(%rbp),%ecx
  803d38:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803d3b:	89 c6                	mov    %eax,%esi
  803d3d:	48 bf 5b 4f 80 00 00 	movabs $0x804f5b,%rdi
  803d44:	00 00 00 
  803d47:	b8 00 00 00 00       	mov    $0x0,%eax
  803d4c:	49 b8 a8 08 80 00 00 	movabs $0x8008a8,%r8
  803d53:	00 00 00 
  803d56:	41 ff d0             	callq  *%r8
  803d59:	e9 4a ff ff ff       	jmpq   803ca8 <_pipeisclosed+0x11>
  803d5e:	e9 45 ff ff ff       	jmpq   803ca8 <_pipeisclosed+0x11>
  803d63:	48 83 c4 28          	add    $0x28,%rsp
  803d67:	5b                   	pop    %rbx
  803d68:	5d                   	pop    %rbp
  803d69:	c3                   	retq   

0000000000803d6a <pipeisclosed>:
  803d6a:	55                   	push   %rbp
  803d6b:	48 89 e5             	mov    %rsp,%rbp
  803d6e:	48 83 ec 30          	sub    $0x30,%rsp
  803d72:	89 7d dc             	mov    %edi,-0x24(%rbp)
  803d75:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  803d79:	8b 45 dc             	mov    -0x24(%rbp),%eax
  803d7c:	48 89 d6             	mov    %rdx,%rsi
  803d7f:	89 c7                	mov    %eax,%edi
  803d81:	48 b8 50 23 80 00 00 	movabs $0x802350,%rax
  803d88:	00 00 00 
  803d8b:	ff d0                	callq  *%rax
  803d8d:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803d90:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803d94:	79 05                	jns    803d9b <pipeisclosed+0x31>
  803d96:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803d99:	eb 31                	jmp    803dcc <pipeisclosed+0x62>
  803d9b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  803d9f:	48 89 c7             	mov    %rax,%rdi
  803da2:	48 b8 8d 22 80 00 00 	movabs $0x80228d,%rax
  803da9:	00 00 00 
  803dac:	ff d0                	callq  *%rax
  803dae:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  803db2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  803db6:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803dba:	48 89 d6             	mov    %rdx,%rsi
  803dbd:	48 89 c7             	mov    %rax,%rdi
  803dc0:	48 b8 97 3c 80 00 00 	movabs $0x803c97,%rax
  803dc7:	00 00 00 
  803dca:	ff d0                	callq  *%rax
  803dcc:	c9                   	leaveq 
  803dcd:	c3                   	retq   

0000000000803dce <devpipe_read>:
  803dce:	55                   	push   %rbp
  803dcf:	48 89 e5             	mov    %rsp,%rbp
  803dd2:	48 83 ec 40          	sub    $0x40,%rsp
  803dd6:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  803dda:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  803dde:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  803de2:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803de6:	48 89 c7             	mov    %rax,%rdi
  803de9:	48 b8 8d 22 80 00 00 	movabs $0x80228d,%rax
  803df0:	00 00 00 
  803df3:	ff d0                	callq  *%rax
  803df5:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  803df9:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803dfd:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  803e01:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  803e08:	00 
  803e09:	e9 92 00 00 00       	jmpq   803ea0 <devpipe_read+0xd2>
  803e0e:	eb 41                	jmp    803e51 <devpipe_read+0x83>
  803e10:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  803e15:	74 09                	je     803e20 <devpipe_read+0x52>
  803e17:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803e1b:	e9 92 00 00 00       	jmpq   803eb2 <devpipe_read+0xe4>
  803e20:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803e24:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803e28:	48 89 d6             	mov    %rdx,%rsi
  803e2b:	48 89 c7             	mov    %rax,%rdi
  803e2e:	48 b8 97 3c 80 00 00 	movabs $0x803c97,%rax
  803e35:	00 00 00 
  803e38:	ff d0                	callq  *%rax
  803e3a:	85 c0                	test   %eax,%eax
  803e3c:	74 07                	je     803e45 <devpipe_read+0x77>
  803e3e:	b8 00 00 00 00       	mov    $0x0,%eax
  803e43:	eb 6d                	jmp    803eb2 <devpipe_read+0xe4>
  803e45:	48 b8 4e 1d 80 00 00 	movabs $0x801d4e,%rax
  803e4c:	00 00 00 
  803e4f:	ff d0                	callq  *%rax
  803e51:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803e55:	8b 10                	mov    (%rax),%edx
  803e57:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803e5b:	8b 40 04             	mov    0x4(%rax),%eax
  803e5e:	39 c2                	cmp    %eax,%edx
  803e60:	74 ae                	je     803e10 <devpipe_read+0x42>
  803e62:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803e66:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  803e6a:	48 8d 0c 02          	lea    (%rdx,%rax,1),%rcx
  803e6e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803e72:	8b 00                	mov    (%rax),%eax
  803e74:	99                   	cltd   
  803e75:	c1 ea 1b             	shr    $0x1b,%edx
  803e78:	01 d0                	add    %edx,%eax
  803e7a:	83 e0 1f             	and    $0x1f,%eax
  803e7d:	29 d0                	sub    %edx,%eax
  803e7f:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803e83:	48 98                	cltq   
  803e85:	0f b6 44 02 08       	movzbl 0x8(%rdx,%rax,1),%eax
  803e8a:	88 01                	mov    %al,(%rcx)
  803e8c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803e90:	8b 00                	mov    (%rax),%eax
  803e92:	8d 50 01             	lea    0x1(%rax),%edx
  803e95:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803e99:	89 10                	mov    %edx,(%rax)
  803e9b:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  803ea0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803ea4:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  803ea8:	0f 82 60 ff ff ff    	jb     803e0e <devpipe_read+0x40>
  803eae:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803eb2:	c9                   	leaveq 
  803eb3:	c3                   	retq   

0000000000803eb4 <devpipe_write>:
  803eb4:	55                   	push   %rbp
  803eb5:	48 89 e5             	mov    %rsp,%rbp
  803eb8:	48 83 ec 40          	sub    $0x40,%rsp
  803ebc:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  803ec0:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  803ec4:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  803ec8:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803ecc:	48 89 c7             	mov    %rax,%rdi
  803ecf:	48 b8 8d 22 80 00 00 	movabs $0x80228d,%rax
  803ed6:	00 00 00 
  803ed9:	ff d0                	callq  *%rax
  803edb:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  803edf:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803ee3:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  803ee7:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  803eee:	00 
  803eef:	e9 8e 00 00 00       	jmpq   803f82 <devpipe_write+0xce>
  803ef4:	eb 31                	jmp    803f27 <devpipe_write+0x73>
  803ef6:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803efa:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803efe:	48 89 d6             	mov    %rdx,%rsi
  803f01:	48 89 c7             	mov    %rax,%rdi
  803f04:	48 b8 97 3c 80 00 00 	movabs $0x803c97,%rax
  803f0b:	00 00 00 
  803f0e:	ff d0                	callq  *%rax
  803f10:	85 c0                	test   %eax,%eax
  803f12:	74 07                	je     803f1b <devpipe_write+0x67>
  803f14:	b8 00 00 00 00       	mov    $0x0,%eax
  803f19:	eb 79                	jmp    803f94 <devpipe_write+0xe0>
  803f1b:	48 b8 4e 1d 80 00 00 	movabs $0x801d4e,%rax
  803f22:	00 00 00 
  803f25:	ff d0                	callq  *%rax
  803f27:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803f2b:	8b 40 04             	mov    0x4(%rax),%eax
  803f2e:	48 63 d0             	movslq %eax,%rdx
  803f31:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803f35:	8b 00                	mov    (%rax),%eax
  803f37:	48 98                	cltq   
  803f39:	48 83 c0 20          	add    $0x20,%rax
  803f3d:	48 39 c2             	cmp    %rax,%rdx
  803f40:	73 b4                	jae    803ef6 <devpipe_write+0x42>
  803f42:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803f46:	8b 40 04             	mov    0x4(%rax),%eax
  803f49:	99                   	cltd   
  803f4a:	c1 ea 1b             	shr    $0x1b,%edx
  803f4d:	01 d0                	add    %edx,%eax
  803f4f:	83 e0 1f             	and    $0x1f,%eax
  803f52:	29 d0                	sub    %edx,%eax
  803f54:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  803f58:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  803f5c:	48 01 ca             	add    %rcx,%rdx
  803f5f:	0f b6 0a             	movzbl (%rdx),%ecx
  803f62:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803f66:	48 98                	cltq   
  803f68:	88 4c 02 08          	mov    %cl,0x8(%rdx,%rax,1)
  803f6c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803f70:	8b 40 04             	mov    0x4(%rax),%eax
  803f73:	8d 50 01             	lea    0x1(%rax),%edx
  803f76:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803f7a:	89 50 04             	mov    %edx,0x4(%rax)
  803f7d:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  803f82:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803f86:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  803f8a:	0f 82 64 ff ff ff    	jb     803ef4 <devpipe_write+0x40>
  803f90:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803f94:	c9                   	leaveq 
  803f95:	c3                   	retq   

0000000000803f96 <devpipe_stat>:
  803f96:	55                   	push   %rbp
  803f97:	48 89 e5             	mov    %rsp,%rbp
  803f9a:	48 83 ec 20          	sub    $0x20,%rsp
  803f9e:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  803fa2:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  803fa6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  803faa:	48 89 c7             	mov    %rax,%rdi
  803fad:	48 b8 8d 22 80 00 00 	movabs $0x80228d,%rax
  803fb4:	00 00 00 
  803fb7:	ff d0                	callq  *%rax
  803fb9:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  803fbd:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803fc1:	48 be 6e 4f 80 00 00 	movabs $0x804f6e,%rsi
  803fc8:	00 00 00 
  803fcb:	48 89 c7             	mov    %rax,%rdi
  803fce:	48 b8 5d 14 80 00 00 	movabs $0x80145d,%rax
  803fd5:	00 00 00 
  803fd8:	ff d0                	callq  *%rax
  803fda:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803fde:	8b 50 04             	mov    0x4(%rax),%edx
  803fe1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803fe5:	8b 00                	mov    (%rax),%eax
  803fe7:	29 c2                	sub    %eax,%edx
  803fe9:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803fed:	89 90 80 00 00 00    	mov    %edx,0x80(%rax)
  803ff3:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803ff7:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%rax)
  803ffe:	00 00 00 
  804001:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  804005:	48 b9 e0 60 80 00 00 	movabs $0x8060e0,%rcx
  80400c:	00 00 00 
  80400f:	48 89 88 88 00 00 00 	mov    %rcx,0x88(%rax)
  804016:	b8 00 00 00 00       	mov    $0x0,%eax
  80401b:	c9                   	leaveq 
  80401c:	c3                   	retq   

000000000080401d <devpipe_close>:
  80401d:	55                   	push   %rbp
  80401e:	48 89 e5             	mov    %rsp,%rbp
  804021:	48 83 ec 10          	sub    $0x10,%rsp
  804025:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  804029:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80402d:	48 89 c6             	mov    %rax,%rsi
  804030:	bf 00 00 00 00       	mov    $0x0,%edi
  804035:	48 b8 37 1e 80 00 00 	movabs $0x801e37,%rax
  80403c:	00 00 00 
  80403f:	ff d0                	callq  *%rax
  804041:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  804045:	48 89 c7             	mov    %rax,%rdi
  804048:	48 b8 8d 22 80 00 00 	movabs $0x80228d,%rax
  80404f:	00 00 00 
  804052:	ff d0                	callq  *%rax
  804054:	48 89 c6             	mov    %rax,%rsi
  804057:	bf 00 00 00 00       	mov    $0x0,%edi
  80405c:	48 b8 37 1e 80 00 00 	movabs $0x801e37,%rax
  804063:	00 00 00 
  804066:	ff d0                	callq  *%rax
  804068:	c9                   	leaveq 
  804069:	c3                   	retq   

000000000080406a <wait>:
  80406a:	55                   	push   %rbp
  80406b:	48 89 e5             	mov    %rsp,%rbp
  80406e:	48 83 ec 20          	sub    $0x20,%rsp
  804072:	89 7d ec             	mov    %edi,-0x14(%rbp)
  804075:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  804079:	75 35                	jne    8040b0 <wait+0x46>
  80407b:	48 b9 75 4f 80 00 00 	movabs $0x804f75,%rcx
  804082:	00 00 00 
  804085:	48 ba 80 4f 80 00 00 	movabs $0x804f80,%rdx
  80408c:	00 00 00 
  80408f:	be 0a 00 00 00       	mov    $0xa,%esi
  804094:	48 bf 95 4f 80 00 00 	movabs $0x804f95,%rdi
  80409b:	00 00 00 
  80409e:	b8 00 00 00 00       	mov    $0x0,%eax
  8040a3:	49 b8 b2 43 80 00 00 	movabs $0x8043b2,%r8
  8040aa:	00 00 00 
  8040ad:	41 ff d0             	callq  *%r8
  8040b0:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8040b3:	25 ff 03 00 00       	and    $0x3ff,%eax
  8040b8:	48 98                	cltq   
  8040ba:	48 69 d0 68 01 00 00 	imul   $0x168,%rax,%rdx
  8040c1:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  8040c8:	00 00 00 
  8040cb:	48 01 d0             	add    %rdx,%rax
  8040ce:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8040d2:	eb 0c                	jmp    8040e0 <wait+0x76>
  8040d4:	48 b8 4e 1d 80 00 00 	movabs $0x801d4e,%rax
  8040db:	00 00 00 
  8040de:	ff d0                	callq  *%rax
  8040e0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8040e4:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  8040ea:	3b 45 ec             	cmp    -0x14(%rbp),%eax
  8040ed:	75 0e                	jne    8040fd <wait+0x93>
  8040ef:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8040f3:	8b 80 d4 00 00 00    	mov    0xd4(%rax),%eax
  8040f9:	85 c0                	test   %eax,%eax
  8040fb:	75 d7                	jne    8040d4 <wait+0x6a>
  8040fd:	c9                   	leaveq 
  8040fe:	c3                   	retq   

00000000008040ff <cputchar>:
  8040ff:	55                   	push   %rbp
  804100:	48 89 e5             	mov    %rsp,%rbp
  804103:	48 83 ec 20          	sub    $0x20,%rsp
  804107:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80410a:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80410d:	88 45 ff             	mov    %al,-0x1(%rbp)
  804110:	48 8d 45 ff          	lea    -0x1(%rbp),%rax
  804114:	be 01 00 00 00       	mov    $0x1,%esi
  804119:	48 89 c7             	mov    %rax,%rdi
  80411c:	48 b8 44 1c 80 00 00 	movabs $0x801c44,%rax
  804123:	00 00 00 
  804126:	ff d0                	callq  *%rax
  804128:	c9                   	leaveq 
  804129:	c3                   	retq   

000000000080412a <getchar>:
  80412a:	55                   	push   %rbp
  80412b:	48 89 e5             	mov    %rsp,%rbp
  80412e:	48 83 ec 10          	sub    $0x10,%rsp
  804132:	48 8d 45 fb          	lea    -0x5(%rbp),%rax
  804136:	ba 01 00 00 00       	mov    $0x1,%edx
  80413b:	48 89 c6             	mov    %rax,%rsi
  80413e:	bf 00 00 00 00       	mov    $0x0,%edi
  804143:	48 b8 82 27 80 00 00 	movabs $0x802782,%rax
  80414a:	00 00 00 
  80414d:	ff d0                	callq  *%rax
  80414f:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804152:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  804156:	79 05                	jns    80415d <getchar+0x33>
  804158:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80415b:	eb 14                	jmp    804171 <getchar+0x47>
  80415d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  804161:	7f 07                	jg     80416a <getchar+0x40>
  804163:	b8 f7 ff ff ff       	mov    $0xfffffff7,%eax
  804168:	eb 07                	jmp    804171 <getchar+0x47>
  80416a:	0f b6 45 fb          	movzbl -0x5(%rbp),%eax
  80416e:	0f b6 c0             	movzbl %al,%eax
  804171:	c9                   	leaveq 
  804172:	c3                   	retq   

0000000000804173 <iscons>:
  804173:	55                   	push   %rbp
  804174:	48 89 e5             	mov    %rsp,%rbp
  804177:	48 83 ec 20          	sub    $0x20,%rsp
  80417b:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80417e:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  804182:	8b 45 ec             	mov    -0x14(%rbp),%eax
  804185:	48 89 d6             	mov    %rdx,%rsi
  804188:	89 c7                	mov    %eax,%edi
  80418a:	48 b8 50 23 80 00 00 	movabs $0x802350,%rax
  804191:	00 00 00 
  804194:	ff d0                	callq  *%rax
  804196:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804199:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80419d:	79 05                	jns    8041a4 <iscons+0x31>
  80419f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8041a2:	eb 1a                	jmp    8041be <iscons+0x4b>
  8041a4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8041a8:	8b 10                	mov    (%rax),%edx
  8041aa:	48 b8 20 61 80 00 00 	movabs $0x806120,%rax
  8041b1:	00 00 00 
  8041b4:	8b 00                	mov    (%rax),%eax
  8041b6:	39 c2                	cmp    %eax,%edx
  8041b8:	0f 94 c0             	sete   %al
  8041bb:	0f b6 c0             	movzbl %al,%eax
  8041be:	c9                   	leaveq 
  8041bf:	c3                   	retq   

00000000008041c0 <opencons>:
  8041c0:	55                   	push   %rbp
  8041c1:	48 89 e5             	mov    %rsp,%rbp
  8041c4:	48 83 ec 10          	sub    $0x10,%rsp
  8041c8:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  8041cc:	48 89 c7             	mov    %rax,%rdi
  8041cf:	48 b8 b8 22 80 00 00 	movabs $0x8022b8,%rax
  8041d6:	00 00 00 
  8041d9:	ff d0                	callq  *%rax
  8041db:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8041de:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8041e2:	79 05                	jns    8041e9 <opencons+0x29>
  8041e4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8041e7:	eb 5b                	jmp    804244 <opencons+0x84>
  8041e9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8041ed:	ba 07 04 00 00       	mov    $0x407,%edx
  8041f2:	48 89 c6             	mov    %rax,%rsi
  8041f5:	bf 00 00 00 00       	mov    $0x0,%edi
  8041fa:	48 b8 8c 1d 80 00 00 	movabs $0x801d8c,%rax
  804201:	00 00 00 
  804204:	ff d0                	callq  *%rax
  804206:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804209:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80420d:	79 05                	jns    804214 <opencons+0x54>
  80420f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804212:	eb 30                	jmp    804244 <opencons+0x84>
  804214:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  804218:	48 ba 20 61 80 00 00 	movabs $0x806120,%rdx
  80421f:	00 00 00 
  804222:	8b 12                	mov    (%rdx),%edx
  804224:	89 10                	mov    %edx,(%rax)
  804226:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80422a:	c7 40 08 02 00 00 00 	movl   $0x2,0x8(%rax)
  804231:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  804235:	48 89 c7             	mov    %rax,%rdi
  804238:	48 b8 6a 22 80 00 00 	movabs $0x80226a,%rax
  80423f:	00 00 00 
  804242:	ff d0                	callq  *%rax
  804244:	c9                   	leaveq 
  804245:	c3                   	retq   

0000000000804246 <devcons_read>:
  804246:	55                   	push   %rbp
  804247:	48 89 e5             	mov    %rsp,%rbp
  80424a:	48 83 ec 30          	sub    $0x30,%rsp
  80424e:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  804252:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  804256:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80425a:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  80425f:	75 07                	jne    804268 <devcons_read+0x22>
  804261:	b8 00 00 00 00       	mov    $0x0,%eax
  804266:	eb 4b                	jmp    8042b3 <devcons_read+0x6d>
  804268:	eb 0c                	jmp    804276 <devcons_read+0x30>
  80426a:	48 b8 4e 1d 80 00 00 	movabs $0x801d4e,%rax
  804271:	00 00 00 
  804274:	ff d0                	callq  *%rax
  804276:	48 b8 8e 1c 80 00 00 	movabs $0x801c8e,%rax
  80427d:	00 00 00 
  804280:	ff d0                	callq  *%rax
  804282:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804285:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  804289:	74 df                	je     80426a <devcons_read+0x24>
  80428b:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80428f:	79 05                	jns    804296 <devcons_read+0x50>
  804291:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804294:	eb 1d                	jmp    8042b3 <devcons_read+0x6d>
  804296:	83 7d fc 04          	cmpl   $0x4,-0x4(%rbp)
  80429a:	75 07                	jne    8042a3 <devcons_read+0x5d>
  80429c:	b8 00 00 00 00       	mov    $0x0,%eax
  8042a1:	eb 10                	jmp    8042b3 <devcons_read+0x6d>
  8042a3:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8042a6:	89 c2                	mov    %eax,%edx
  8042a8:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8042ac:	88 10                	mov    %dl,(%rax)
  8042ae:	b8 01 00 00 00       	mov    $0x1,%eax
  8042b3:	c9                   	leaveq 
  8042b4:	c3                   	retq   

00000000008042b5 <devcons_write>:
  8042b5:	55                   	push   %rbp
  8042b6:	48 89 e5             	mov    %rsp,%rbp
  8042b9:	48 81 ec b0 00 00 00 	sub    $0xb0,%rsp
  8042c0:	48 89 bd 68 ff ff ff 	mov    %rdi,-0x98(%rbp)
  8042c7:	48 89 b5 60 ff ff ff 	mov    %rsi,-0xa0(%rbp)
  8042ce:	48 89 95 58 ff ff ff 	mov    %rdx,-0xa8(%rbp)
  8042d5:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8042dc:	eb 76                	jmp    804354 <devcons_write+0x9f>
  8042de:	48 8b 85 58 ff ff ff 	mov    -0xa8(%rbp),%rax
  8042e5:	89 c2                	mov    %eax,%edx
  8042e7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8042ea:	29 c2                	sub    %eax,%edx
  8042ec:	89 d0                	mov    %edx,%eax
  8042ee:	89 45 f8             	mov    %eax,-0x8(%rbp)
  8042f1:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8042f4:	83 f8 7f             	cmp    $0x7f,%eax
  8042f7:	76 07                	jbe    804300 <devcons_write+0x4b>
  8042f9:	c7 45 f8 7f 00 00 00 	movl   $0x7f,-0x8(%rbp)
  804300:	8b 45 f8             	mov    -0x8(%rbp),%eax
  804303:	48 63 d0             	movslq %eax,%rdx
  804306:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804309:	48 63 c8             	movslq %eax,%rcx
  80430c:	48 8b 85 60 ff ff ff 	mov    -0xa0(%rbp),%rax
  804313:	48 01 c1             	add    %rax,%rcx
  804316:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
  80431d:	48 89 ce             	mov    %rcx,%rsi
  804320:	48 89 c7             	mov    %rax,%rdi
  804323:	48 b8 81 17 80 00 00 	movabs $0x801781,%rax
  80432a:	00 00 00 
  80432d:	ff d0                	callq  *%rax
  80432f:	8b 45 f8             	mov    -0x8(%rbp),%eax
  804332:	48 63 d0             	movslq %eax,%rdx
  804335:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
  80433c:	48 89 d6             	mov    %rdx,%rsi
  80433f:	48 89 c7             	mov    %rax,%rdi
  804342:	48 b8 44 1c 80 00 00 	movabs $0x801c44,%rax
  804349:	00 00 00 
  80434c:	ff d0                	callq  *%rax
  80434e:	8b 45 f8             	mov    -0x8(%rbp),%eax
  804351:	01 45 fc             	add    %eax,-0x4(%rbp)
  804354:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804357:	48 98                	cltq   
  804359:	48 3b 85 58 ff ff ff 	cmp    -0xa8(%rbp),%rax
  804360:	0f 82 78 ff ff ff    	jb     8042de <devcons_write+0x29>
  804366:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804369:	c9                   	leaveq 
  80436a:	c3                   	retq   

000000000080436b <devcons_close>:
  80436b:	55                   	push   %rbp
  80436c:	48 89 e5             	mov    %rsp,%rbp
  80436f:	48 83 ec 08          	sub    $0x8,%rsp
  804373:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  804377:	b8 00 00 00 00       	mov    $0x0,%eax
  80437c:	c9                   	leaveq 
  80437d:	c3                   	retq   

000000000080437e <devcons_stat>:
  80437e:	55                   	push   %rbp
  80437f:	48 89 e5             	mov    %rsp,%rbp
  804382:	48 83 ec 10          	sub    $0x10,%rsp
  804386:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80438a:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  80438e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  804392:	48 be a8 4f 80 00 00 	movabs $0x804fa8,%rsi
  804399:	00 00 00 
  80439c:	48 89 c7             	mov    %rax,%rdi
  80439f:	48 b8 5d 14 80 00 00 	movabs $0x80145d,%rax
  8043a6:	00 00 00 
  8043a9:	ff d0                	callq  *%rax
  8043ab:	b8 00 00 00 00       	mov    $0x0,%eax
  8043b0:	c9                   	leaveq 
  8043b1:	c3                   	retq   

00000000008043b2 <_panic>:
  8043b2:	55                   	push   %rbp
  8043b3:	48 89 e5             	mov    %rsp,%rbp
  8043b6:	53                   	push   %rbx
  8043b7:	48 81 ec f8 00 00 00 	sub    $0xf8,%rsp
  8043be:	48 89 bd 18 ff ff ff 	mov    %rdi,-0xe8(%rbp)
  8043c5:	89 b5 14 ff ff ff    	mov    %esi,-0xec(%rbp)
  8043cb:	48 89 8d 58 ff ff ff 	mov    %rcx,-0xa8(%rbp)
  8043d2:	4c 89 85 60 ff ff ff 	mov    %r8,-0xa0(%rbp)
  8043d9:	4c 89 8d 68 ff ff ff 	mov    %r9,-0x98(%rbp)
  8043e0:	84 c0                	test   %al,%al
  8043e2:	74 23                	je     804407 <_panic+0x55>
  8043e4:	0f 29 85 70 ff ff ff 	movaps %xmm0,-0x90(%rbp)
  8043eb:	0f 29 4d 80          	movaps %xmm1,-0x80(%rbp)
  8043ef:	0f 29 55 90          	movaps %xmm2,-0x70(%rbp)
  8043f3:	0f 29 5d a0          	movaps %xmm3,-0x60(%rbp)
  8043f7:	0f 29 65 b0          	movaps %xmm4,-0x50(%rbp)
  8043fb:	0f 29 6d c0          	movaps %xmm5,-0x40(%rbp)
  8043ff:	0f 29 75 d0          	movaps %xmm6,-0x30(%rbp)
  804403:	0f 29 7d e0          	movaps %xmm7,-0x20(%rbp)
  804407:	48 89 95 08 ff ff ff 	mov    %rdx,-0xf8(%rbp)
  80440e:	c7 85 28 ff ff ff 18 	movl   $0x18,-0xd8(%rbp)
  804415:	00 00 00 
  804418:	c7 85 2c ff ff ff 30 	movl   $0x30,-0xd4(%rbp)
  80441f:	00 00 00 
  804422:	48 8d 45 10          	lea    0x10(%rbp),%rax
  804426:	48 89 85 30 ff ff ff 	mov    %rax,-0xd0(%rbp)
  80442d:	48 8d 85 40 ff ff ff 	lea    -0xc0(%rbp),%rax
  804434:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  80443b:	48 b8 00 60 80 00 00 	movabs $0x806000,%rax
  804442:	00 00 00 
  804445:	48 8b 18             	mov    (%rax),%rbx
  804448:	48 b8 10 1d 80 00 00 	movabs $0x801d10,%rax
  80444f:	00 00 00 
  804452:	ff d0                	callq  *%rax
  804454:	8b 8d 14 ff ff ff    	mov    -0xec(%rbp),%ecx
  80445a:	48 8b 95 18 ff ff ff 	mov    -0xe8(%rbp),%rdx
  804461:	41 89 c8             	mov    %ecx,%r8d
  804464:	48 89 d1             	mov    %rdx,%rcx
  804467:	48 89 da             	mov    %rbx,%rdx
  80446a:	89 c6                	mov    %eax,%esi
  80446c:	48 bf b0 4f 80 00 00 	movabs $0x804fb0,%rdi
  804473:	00 00 00 
  804476:	b8 00 00 00 00       	mov    $0x0,%eax
  80447b:	49 b9 a8 08 80 00 00 	movabs $0x8008a8,%r9
  804482:	00 00 00 
  804485:	41 ff d1             	callq  *%r9
  804488:	48 8d 95 28 ff ff ff 	lea    -0xd8(%rbp),%rdx
  80448f:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  804496:	48 89 d6             	mov    %rdx,%rsi
  804499:	48 89 c7             	mov    %rax,%rdi
  80449c:	48 b8 fc 07 80 00 00 	movabs $0x8007fc,%rax
  8044a3:	00 00 00 
  8044a6:	ff d0                	callq  *%rax
  8044a8:	48 bf d3 4f 80 00 00 	movabs $0x804fd3,%rdi
  8044af:	00 00 00 
  8044b2:	b8 00 00 00 00       	mov    $0x0,%eax
  8044b7:	48 ba a8 08 80 00 00 	movabs $0x8008a8,%rdx
  8044be:	00 00 00 
  8044c1:	ff d2                	callq  *%rdx
  8044c3:	cc                   	int3   
  8044c4:	eb fd                	jmp    8044c3 <_panic+0x111>

00000000008044c6 <ipc_recv>:
  8044c6:	55                   	push   %rbp
  8044c7:	48 89 e5             	mov    %rsp,%rbp
  8044ca:	48 83 ec 30          	sub    $0x30,%rsp
  8044ce:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8044d2:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8044d6:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8044da:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  8044df:	75 0e                	jne    8044ef <ipc_recv+0x29>
  8044e1:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  8044e8:	00 00 00 
  8044eb:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  8044ef:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8044f3:	48 89 c7             	mov    %rax,%rdi
  8044f6:	48 b8 b5 1f 80 00 00 	movabs $0x801fb5,%rax
  8044fd:	00 00 00 
  804500:	ff d0                	callq  *%rax
  804502:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804505:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  804509:	79 27                	jns    804532 <ipc_recv+0x6c>
  80450b:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  804510:	74 0a                	je     80451c <ipc_recv+0x56>
  804512:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  804516:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
  80451c:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  804521:	74 0a                	je     80452d <ipc_recv+0x67>
  804523:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  804527:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
  80452d:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804530:	eb 53                	jmp    804585 <ipc_recv+0xbf>
  804532:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  804537:	74 19                	je     804552 <ipc_recv+0x8c>
  804539:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  804540:	00 00 00 
  804543:	48 8b 00             	mov    (%rax),%rax
  804546:	8b 90 0c 01 00 00    	mov    0x10c(%rax),%edx
  80454c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  804550:	89 10                	mov    %edx,(%rax)
  804552:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  804557:	74 19                	je     804572 <ipc_recv+0xac>
  804559:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  804560:	00 00 00 
  804563:	48 8b 00             	mov    (%rax),%rax
  804566:	8b 90 10 01 00 00    	mov    0x110(%rax),%edx
  80456c:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  804570:	89 10                	mov    %edx,(%rax)
  804572:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  804579:	00 00 00 
  80457c:	48 8b 00             	mov    (%rax),%rax
  80457f:	8b 80 08 01 00 00    	mov    0x108(%rax),%eax
  804585:	c9                   	leaveq 
  804586:	c3                   	retq   

0000000000804587 <ipc_send>:
  804587:	55                   	push   %rbp
  804588:	48 89 e5             	mov    %rsp,%rbp
  80458b:	48 83 ec 30          	sub    $0x30,%rsp
  80458f:	89 7d ec             	mov    %edi,-0x14(%rbp)
  804592:	89 75 e8             	mov    %esi,-0x18(%rbp)
  804595:	48 89 55 e0          	mov    %rdx,-0x20(%rbp)
  804599:	89 4d dc             	mov    %ecx,-0x24(%rbp)
  80459c:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  8045a1:	75 10                	jne    8045b3 <ipc_send+0x2c>
  8045a3:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  8045aa:	00 00 00 
  8045ad:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  8045b1:	eb 0e                	jmp    8045c1 <ipc_send+0x3a>
  8045b3:	eb 0c                	jmp    8045c1 <ipc_send+0x3a>
  8045b5:	48 b8 4e 1d 80 00 00 	movabs $0x801d4e,%rax
  8045bc:	00 00 00 
  8045bf:	ff d0                	callq  *%rax
  8045c1:	8b 75 e8             	mov    -0x18(%rbp),%esi
  8045c4:	8b 4d dc             	mov    -0x24(%rbp),%ecx
  8045c7:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8045cb:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8045ce:	89 c7                	mov    %eax,%edi
  8045d0:	48 b8 60 1f 80 00 00 	movabs $0x801f60,%rax
  8045d7:	00 00 00 
  8045da:	ff d0                	callq  *%rax
  8045dc:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8045df:	83 7d fc f8          	cmpl   $0xfffffff8,-0x4(%rbp)
  8045e3:	74 d0                	je     8045b5 <ipc_send+0x2e>
  8045e5:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8045e9:	79 30                	jns    80461b <ipc_send+0x94>
  8045eb:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8045ee:	89 c1                	mov    %eax,%ecx
  8045f0:	48 ba d5 4f 80 00 00 	movabs $0x804fd5,%rdx
  8045f7:	00 00 00 
  8045fa:	be 44 00 00 00       	mov    $0x44,%esi
  8045ff:	48 bf eb 4f 80 00 00 	movabs $0x804feb,%rdi
  804606:	00 00 00 
  804609:	b8 00 00 00 00       	mov    $0x0,%eax
  80460e:	49 b8 b2 43 80 00 00 	movabs $0x8043b2,%r8
  804615:	00 00 00 
  804618:	41 ff d0             	callq  *%r8
  80461b:	c9                   	leaveq 
  80461c:	c3                   	retq   

000000000080461d <ipc_find_env>:
  80461d:	55                   	push   %rbp
  80461e:	48 89 e5             	mov    %rsp,%rbp
  804621:	48 83 ec 14          	sub    $0x14,%rsp
  804625:	89 7d ec             	mov    %edi,-0x14(%rbp)
  804628:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  80462f:	eb 4e                	jmp    80467f <ipc_find_env+0x62>
  804631:	48 ba 00 00 80 00 80 	movabs $0x8000800000,%rdx
  804638:	00 00 00 
  80463b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80463e:	48 98                	cltq   
  804640:	48 69 c0 68 01 00 00 	imul   $0x168,%rax,%rax
  804647:	48 01 d0             	add    %rdx,%rax
  80464a:	48 05 d0 00 00 00    	add    $0xd0,%rax
  804650:	8b 00                	mov    (%rax),%eax
  804652:	3b 45 ec             	cmp    -0x14(%rbp),%eax
  804655:	75 24                	jne    80467b <ipc_find_env+0x5e>
  804657:	48 ba 00 00 80 00 80 	movabs $0x8000800000,%rdx
  80465e:	00 00 00 
  804661:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804664:	48 98                	cltq   
  804666:	48 69 c0 68 01 00 00 	imul   $0x168,%rax,%rax
  80466d:	48 01 d0             	add    %rdx,%rax
  804670:	48 05 c0 00 00 00    	add    $0xc0,%rax
  804676:	8b 40 08             	mov    0x8(%rax),%eax
  804679:	eb 12                	jmp    80468d <ipc_find_env+0x70>
  80467b:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  80467f:	81 7d fc ff 03 00 00 	cmpl   $0x3ff,-0x4(%rbp)
  804686:	7e a9                	jle    804631 <ipc_find_env+0x14>
  804688:	b8 00 00 00 00       	mov    $0x0,%eax
  80468d:	c9                   	leaveq 
  80468e:	c3                   	retq   

000000000080468f <pageref>:
  80468f:	55                   	push   %rbp
  804690:	48 89 e5             	mov    %rsp,%rbp
  804693:	48 83 ec 18          	sub    $0x18,%rsp
  804697:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80469b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80469f:	48 c1 e8 15          	shr    $0x15,%rax
  8046a3:	48 89 c2             	mov    %rax,%rdx
  8046a6:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  8046ad:	01 00 00 
  8046b0:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8046b4:	83 e0 01             	and    $0x1,%eax
  8046b7:	48 85 c0             	test   %rax,%rax
  8046ba:	75 07                	jne    8046c3 <pageref+0x34>
  8046bc:	b8 00 00 00 00       	mov    $0x0,%eax
  8046c1:	eb 53                	jmp    804716 <pageref+0x87>
  8046c3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8046c7:	48 c1 e8 0c          	shr    $0xc,%rax
  8046cb:	48 89 c2             	mov    %rax,%rdx
  8046ce:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  8046d5:	01 00 00 
  8046d8:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8046dc:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8046e0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8046e4:	83 e0 01             	and    $0x1,%eax
  8046e7:	48 85 c0             	test   %rax,%rax
  8046ea:	75 07                	jne    8046f3 <pageref+0x64>
  8046ec:	b8 00 00 00 00       	mov    $0x0,%eax
  8046f1:	eb 23                	jmp    804716 <pageref+0x87>
  8046f3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8046f7:	48 c1 e8 0c          	shr    $0xc,%rax
  8046fb:	48 89 c2             	mov    %rax,%rdx
  8046fe:	48 b8 00 00 a0 00 80 	movabs $0x8000a00000,%rax
  804705:	00 00 00 
  804708:	48 c1 e2 04          	shl    $0x4,%rdx
  80470c:	48 01 d0             	add    %rdx,%rax
  80470f:	0f b7 40 08          	movzwl 0x8(%rax),%eax
  804713:	0f b7 c0             	movzwl %ax,%eax
  804716:	c9                   	leaveq 
  804717:	c3                   	retq   
