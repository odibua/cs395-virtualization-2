
vmm/guest/obj/user/vmm:     file format elf64-x86-64


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
  80003c:	e8 23 06 00 00       	callq  800664 <libmain>
1:	jmp 1b
  800041:	eb fe                	jmp    800041 <args_exist+0xe>

0000000000800043 <map_in_guest>:
//
// Hint: Call sys_ept_map() for mapping page.
static int
map_in_guest(envid_t guest, uintptr_t gpa, size_t memsz,
			 int fd, size_t filesz, off_t fileoffset)
{
  800043:	55                   	push   %rbp
  800044:	48 89 e5             	mov    %rsp,%rbp
  800047:	48 83 ec 50          	sub    $0x50,%rsp
  80004b:	89 7d dc             	mov    %edi,-0x24(%rbp)
  80004e:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  800052:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  800056:	89 4d d8             	mov    %ecx,-0x28(%rbp)
  800059:	4c 89 45 c0          	mov    %r8,-0x40(%rbp)
  80005d:	44 89 4d bc          	mov    %r9d,-0x44(%rbp)
	/* Your code here */
	int index = 0;
  800061:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
	int statusFlag = -1;
  800068:	c7 45 f8 ff ff ff ff 	movl   $0xffffffff,-0x8(%rbp)

	//Round down to the nearest multiple of PGSIZE starting at guest's phy addr
	if (PGOFF(gpa) != 0)
  80006f:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800073:	25 ff 0f 00 00       	and    $0xfff,%eax
  800078:	48 85 c0             	test   %rax,%rax
  80007b:	74 08                	je     800085 <map_in_guest+0x42>
		ROUNDDOWN(gpa, PGSIZE);
  80007d:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800081:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	for (index = 0; index < memsz; index += PGSIZE)
  800085:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  80008c:	e9 81 02 00 00       	jmpq   800312 <map_in_guest+0x2cf>
	{
		if (index < filesz)
  800091:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800094:	48 98                	cltq   
  800096:	48 3b 45 c0          	cmp    -0x40(%rbp),%rax
  80009a:	0f 83 77 01 00 00    	jae    800217 <map_in_guest+0x1d4>
		{
			/* alloc a page in the env,temp map to use, permission flags as arg 3
			PTE_P- is present check */
			statusFlag = sys_page_alloc(thisenv->env_id, UTEMP, PTE_P | PTE_U | PTE_W);
  8000a0:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  8000a7:	00 00 00 
  8000aa:	48 8b 00             	mov    (%rax),%rax
  8000ad:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  8000b3:	ba 07 00 00 00       	mov    $0x7,%edx
  8000b8:	be 00 00 40 00       	mov    $0x400000,%esi
  8000bd:	89 c7                	mov    %eax,%edi
  8000bf:	48 b8 27 1e 80 00 00 	movabs $0x801e27,%rax
  8000c6:	00 00 00 
  8000c9:	ff d0                	callq  *%rax
  8000cb:	89 45 f8             	mov    %eax,-0x8(%rbp)

			if (statusFlag < 0)
  8000ce:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8000d2:	79 08                	jns    8000dc <map_in_guest+0x99>
				return statusFlag;
  8000d4:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8000d7:	e9 4a 02 00 00       	jmpq   800326 <map_in_guest+0x2e3>

			// from offset loc, move page by page, index increments by pagesize
			statusFlag = seek(fd, fileoffset + index);
  8000dc:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8000df:	8b 55 bc             	mov    -0x44(%rbp),%edx
  8000e2:	01 c2                	add    %eax,%edx
  8000e4:	8b 45 d8             	mov    -0x28(%rbp),%eax
  8000e7:	89 d6                	mov    %edx,%esi
  8000e9:	89 c7                	mov    %eax,%edi
  8000eb:	48 b8 3d 29 80 00 00 	movabs $0x80293d,%rax
  8000f2:	00 00 00 
  8000f5:	ff d0                	callq  *%rax
  8000f7:	89 45 f8             	mov    %eax,-0x8(%rbp)
			if (statusFlag < 0)
  8000fa:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8000fe:	79 08                	jns    800108 <map_in_guest+0xc5>
				return statusFlag;
  800100:	8b 45 f8             	mov    -0x8(%rbp),%eax
  800103:	e9 1e 02 00 00       	jmpq   800326 <map_in_guest+0x2e3>

			// read opened file
			statusFlag = readn(fd, UTEMP, MIN(PGSIZE, filesz - index));
  800108:	c7 45 ec 00 10 00 00 	movl   $0x1000,-0x14(%rbp)
  80010f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800112:	48 98                	cltq   
  800114:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800118:	48 29 c2             	sub    %rax,%rdx
  80011b:	48 89 d0             	mov    %rdx,%rax
  80011e:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  800122:	8b 45 ec             	mov    -0x14(%rbp),%eax
  800125:	48 63 d0             	movslq %eax,%rdx
  800128:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80012c:	48 39 c2             	cmp    %rax,%rdx
  80012f:	48 0f 47 d0          	cmova  %rax,%rdx
  800133:	8b 45 d8             	mov    -0x28(%rbp),%eax
  800136:	be 00 00 40 00       	mov    $0x400000,%esi
  80013b:	89 c7                	mov    %eax,%edi
  80013d:	48 b8 f4 27 80 00 00 	movabs $0x8027f4,%rax
  800144:	00 00 00 
  800147:	ff d0                	callq  *%rax
  800149:	89 45 f8             	mov    %eax,-0x8(%rbp)
			if (statusFlag < 0)
  80014c:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  800150:	79 08                	jns    80015a <map_in_guest+0x117>
				return statusFlag;
  800152:	8b 45 f8             	mov    -0x8(%rbp),%eax
  800155:	e9 cc 01 00 00       	jmpq   800326 <map_in_guest+0x2e3>

			// page to be mapped for guest
			statusFlag = sys_ept_map(thisenv->env_id, (void *)UTEMP, guest, (void *)(gpa + index), __EPTE_FULL);
  80015a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80015d:	48 63 d0             	movslq %eax,%rdx
  800160:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800164:	48 01 d0             	add    %rdx,%rax
  800167:	48 89 c1             	mov    %rax,%rcx
  80016a:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  800171:	00 00 00 
  800174:	48 8b 00             	mov    (%rax),%rax
  800177:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  80017d:	8b 55 dc             	mov    -0x24(%rbp),%edx
  800180:	41 b8 07 00 00 00    	mov    $0x7,%r8d
  800186:	be 00 00 40 00       	mov    $0x400000,%esi
  80018b:	89 c7                	mov    %eax,%edi
  80018d:	48 b8 62 21 80 00 00 	movabs $0x802162,%rax
  800194:	00 00 00 
  800197:	ff d0                	callq  *%rax
  800199:	89 45 f8             	mov    %eax,-0x8(%rbp)
			if (statusFlag < 0){
  80019c:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8001a0:	79 4a                	jns    8001ec <map_in_guest+0x1a9>
				cprintf("Page map failure (If block): %e", statusFlag);
  8001a2:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8001a5:	89 c6                	mov    %eax,%esi
  8001a7:	48 bf 20 46 80 00 00 	movabs $0x804620,%rdi
  8001ae:	00 00 00 
  8001b1:	b8 00 00 00 00       	mov    $0x0,%eax
  8001b6:	48 ba 43 09 80 00 00 	movabs $0x800943,%rdx
  8001bd:	00 00 00 
  8001c0:	ff d2                	callq  *%rdx
				panic("Page map failure - If block");
  8001c2:	48 ba 40 46 80 00 00 	movabs $0x804640,%rdx
  8001c9:	00 00 00 
  8001cc:	be 38 00 00 00       	mov    $0x38,%esi
  8001d1:	48 bf 5c 46 80 00 00 	movabs $0x80465c,%rdi
  8001d8:	00 00 00 
  8001db:	b8 00 00 00 00       	mov    $0x0,%eax
  8001e0:	48 b9 0a 07 80 00 00 	movabs $0x80070a,%rcx
  8001e7:	00 00 00 
  8001ea:	ff d1                	callq  *%rcx
			}
			// Unmap - not req anymore
			sys_page_unmap(thisenv->env_id, UTEMP);
  8001ec:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  8001f3:	00 00 00 
  8001f6:	48 8b 00             	mov    (%rax),%rax
  8001f9:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  8001ff:	be 00 00 40 00       	mov    $0x400000,%esi
  800204:	89 c7                	mov    %eax,%edi
  800206:	48 b8 d2 1e 80 00 00 	movabs $0x801ed2,%rax
  80020d:	00 00 00 
  800210:	ff d0                	callq  *%rax
  800212:	e9 f4 00 00 00       	jmpq   80030b <map_in_guest+0x2c8>
		}

		else
		{
			statusFlag = sys_page_alloc(thisenv->env_id, (void *)UTEMP, __EPTE_FULL);
  800217:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  80021e:	00 00 00 
  800221:	48 8b 00             	mov    (%rax),%rax
  800224:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  80022a:	ba 07 00 00 00       	mov    $0x7,%edx
  80022f:	be 00 00 40 00       	mov    $0x400000,%esi
  800234:	89 c7                	mov    %eax,%edi
  800236:	48 b8 27 1e 80 00 00 	movabs $0x801e27,%rax
  80023d:	00 00 00 
  800240:	ff d0                	callq  *%rax
  800242:	89 45 f8             	mov    %eax,-0x8(%rbp)
			if (statusFlag < 0)
  800245:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  800249:	79 08                	jns    800253 <map_in_guest+0x210>
				return statusFlag;
  80024b:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80024e:	e9 d3 00 00 00       	jmpq   800326 <map_in_guest+0x2e3>

			statusFlag = sys_ept_map(thisenv->env_id, UTEMP, guest, (void *)(gpa + index), __EPTE_FULL);
  800253:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800256:	48 63 d0             	movslq %eax,%rdx
  800259:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80025d:	48 01 d0             	add    %rdx,%rax
  800260:	48 89 c1             	mov    %rax,%rcx
  800263:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  80026a:	00 00 00 
  80026d:	48 8b 00             	mov    (%rax),%rax
  800270:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  800276:	8b 55 dc             	mov    -0x24(%rbp),%edx
  800279:	41 b8 07 00 00 00    	mov    $0x7,%r8d
  80027f:	be 00 00 40 00       	mov    $0x400000,%esi
  800284:	89 c7                	mov    %eax,%edi
  800286:	48 b8 62 21 80 00 00 	movabs $0x802162,%rax
  80028d:	00 00 00 
  800290:	ff d0                	callq  *%rax
  800292:	89 45 f8             	mov    %eax,-0x8(%rbp)

			if (statusFlag < 0){
  800295:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  800299:	79 4a                	jns    8002e5 <map_in_guest+0x2a2>
				cprintf("Page map failure (else block): %e", statusFlag);
  80029b:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80029e:	89 c6                	mov    %eax,%esi
  8002a0:	48 bf 68 46 80 00 00 	movabs $0x804668,%rdi
  8002a7:	00 00 00 
  8002aa:	b8 00 00 00 00       	mov    $0x0,%eax
  8002af:	48 ba 43 09 80 00 00 	movabs $0x800943,%rdx
  8002b6:	00 00 00 
  8002b9:	ff d2                	callq  *%rdx
				panic("Page map failure - else block");
  8002bb:	48 ba 8a 46 80 00 00 	movabs $0x80468a,%rdx
  8002c2:	00 00 00 
  8002c5:	be 48 00 00 00       	mov    $0x48,%esi
  8002ca:	48 bf 5c 46 80 00 00 	movabs $0x80465c,%rdi
  8002d1:	00 00 00 
  8002d4:	b8 00 00 00 00       	mov    $0x0,%eax
  8002d9:	48 b9 0a 07 80 00 00 	movabs $0x80070a,%rcx
  8002e0:	00 00 00 
  8002e3:	ff d1                	callq  *%rcx
			}
			//unmap
			sys_page_unmap(thisenv->env_id, UTEMP);
  8002e5:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  8002ec:	00 00 00 
  8002ef:	48 8b 00             	mov    (%rax),%rax
  8002f2:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  8002f8:	be 00 00 40 00       	mov    $0x400000,%esi
  8002fd:	89 c7                	mov    %eax,%edi
  8002ff:	48 b8 d2 1e 80 00 00 	movabs $0x801ed2,%rax
  800306:	00 00 00 
  800309:	ff d0                	callq  *%rax

	//Round down to the nearest multiple of PGSIZE starting at guest's phy addr
	if (PGOFF(gpa) != 0)
		ROUNDDOWN(gpa, PGSIZE);

	for (index = 0; index < memsz; index += PGSIZE)
  80030b:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%rbp)
  800312:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800315:	48 98                	cltq   
  800317:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  80031b:	0f 82 70 fd ff ff    	jb     800091 <map_in_guest+0x4e>
			}
			//unmap
			sys_page_unmap(thisenv->env_id, UTEMP);
		}
	}
	return 0; // success
  800321:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800326:	c9                   	leaveq 
  800327:	c3                   	retq   

0000000000800328 <copy_guest_kern_gpa>:
// Return 0 on success, <0 on error
//
// Hint: compare with ELF parsing in env.c, and use map_in_guest for each segment.
static int
copy_guest_kern_gpa(envid_t guest, char *fname)
{
  800328:	55                   	push   %rbp
  800329:	48 89 e5             	mov    %rsp,%rbp
  80032c:	48 81 ec 40 04 00 00 	sub    $0x440,%rsp
  800333:	89 bd cc fb ff ff    	mov    %edi,-0x434(%rbp)
  800339:	48 89 b5 c0 fb ff ff 	mov    %rsi,-0x440(%rbp)
	/* Your code here */

	int fileDesc = -1; 		//to be able to read
  800340:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%rbp)
	int mapStatus = -1;		
  800347:	c7 45 fc ff ff ff ff 	movl   $0xffffffff,-0x4(%rbp)
	char fileData[1024];	//how much to read into buffer	
	struct Elf *fileHeader;	//binary validation using this struct to be done
	size_t totalRead = 0;	//to error check, binary validation
  80034e:	48 c7 45 e0 00 00 00 	movq   $0x0,-0x20(%rbp)
  800355:	00 

	// open file in readonly mode
	fileDesc = open(fname, O_RDONLY);
  800356:	48 8b 85 c0 fb ff ff 	mov    -0x440(%rbp),%rax
  80035d:	be 00 00 00 00       	mov    $0x0,%esi
  800362:	48 89 c7             	mov    %rax,%rdi
  800365:	48 b8 f5 2b 80 00 00 	movabs $0x802bf5,%rax
  80036c:	00 00 00 
  80036f:	ff d0                	callq  *%rax
  800371:	89 45 ec             	mov    %eax,-0x14(%rbp)

	//error opening file
	if (fileDesc < 0)
  800374:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  800378:	79 0a                	jns    800384 <copy_guest_kern_gpa+0x5c>
		return -E_NOT_FOUND;
  80037a:	b8 f4 ff ff ff       	mov    $0xfffffff4,%eax
  80037f:	e9 4a 01 00 00       	jmpq   8004ce <copy_guest_kern_gpa+0x1a6>

	//if opened, read into buffer
	totalRead = readn(fileDesc, fileData, sizeof(fileData));
  800384:	48 8d 8d d0 fb ff ff 	lea    -0x430(%rbp),%rcx
  80038b:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80038e:	ba 00 04 00 00       	mov    $0x400,%edx
  800393:	48 89 ce             	mov    %rcx,%rsi
  800396:	89 c7                	mov    %eax,%edi
  800398:	48 b8 f4 27 80 00 00 	movabs $0x8027f4,%rax
  80039f:	00 00 00 
  8003a2:	ff d0                	callq  *%rax
  8003a4:	48 98                	cltq   
  8003a6:	48 89 45 e0          	mov    %rax,-0x20(%rbp)

	if (totalRead != sizeof(fileData))
  8003aa:	48 81 7d e0 00 04 00 	cmpq   $0x400,-0x20(%rbp)
  8003b1:	00 
  8003b2:	74 1b                	je     8003cf <copy_guest_kern_gpa+0xa7>
	{ // mismatch in size
		close(fileDesc);
  8003b4:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8003b7:	89 c7                	mov    %eax,%edi
  8003b9:	48 b8 fd 24 80 00 00 	movabs $0x8024fd,%rax
  8003c0:	00 00 00 
  8003c3:	ff d0                	callq  *%rax
		return -E_NOT_FOUND; // ret -12
  8003c5:	b8 f4 ff ff ff       	mov    $0xfffffff4,%eax
  8003ca:	e9 ff 00 00 00       	jmpq   8004ce <copy_guest_kern_gpa+0x1a6>
	}

	fileHeader = (struct Elf *)fileData;
  8003cf:	48 8d 85 d0 fb ff ff 	lea    -0x430(%rbp),%rax
  8003d6:	48 89 45 d8          	mov    %rax,-0x28(%rbp)

	/*recall his header typically starts with a sequence of four unique bytes that are 0x7F followed by 0x45,
	0x4c, and 0x46 which on ASCII translation yields the three letters E, L, and F. 
	ELF_MAGIC = 0x464C457FU : read LSB to MSB */

	if (fileHeader->e_magic != ELF_MAGIC)
  8003da:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8003de:	8b 00                	mov    (%rax),%eax
  8003e0:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
  8003e5:	74 1b                	je     800402 <copy_guest_kern_gpa+0xda>
	{
		close(fileDesc);
  8003e7:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8003ea:	89 c7                	mov    %eax,%edi
  8003ec:	48 b8 fd 24 80 00 00 	movabs $0x8024fd,%rax
  8003f3:	00 00 00 
  8003f6:	ff d0                	callq  *%rax
		return -E_NOT_EXEC; // not a suitable binary ELF was not found in header
  8003f8:	b8 f1 ff ff ff       	mov    $0xfffffff1,%eax
  8003fd:	e9 cc 00 00 00       	jmpq   8004ce <copy_guest_kern_gpa+0x1a6>
	}

	struct Proghdr *prgHdr = (struct Proghdr *)(fileData + fileHeader->e_phoff); //add offset to data and move tp prgHdr 
  800402:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800406:	48 8b 40 20          	mov    0x20(%rax),%rax
  80040a:	48 8d 95 d0 fb ff ff 	lea    -0x430(%rbp),%rdx
  800411:	48 01 d0             	add    %rdx,%rax
  800414:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	struct Proghdr *endPrgHdr = prgHdr + fileHeader->e_phnum; // add more to prghdr, 32 bit offset
  800418:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80041c:	0f b7 40 38          	movzwl 0x38(%rax),%eax
  800420:	0f b7 c0             	movzwl %ax,%eax
  800423:	48 c1 e0 03          	shl    $0x3,%rax
  800427:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  80042e:	00 
  80042f:	48 29 c2             	sub    %rax,%rdx
  800432:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800436:	48 01 d0             	add    %rdx,%rax
  800439:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
	
	//prgHdr is already initialized
	for (; prgHdr < endPrgHdr; prgHdr++)
  80043d:	eb 71                	jmp    8004b0 <copy_guest_kern_gpa+0x188>
		/*The ELF header gets allocated by means of the macros defined in elf.h file. The constant
		*ELF PROG LOAD is carrying the value 1. This is actually the value for p type field of the
		*Proghdr structure. The value of 1 in particular means that the segment type is PT LOAD
		*/

		if (prgHdr->p_type == ELF_PROG_LOAD)
  80043f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800443:	8b 00                	mov    (%rax),%eax
  800445:	83 f8 01             	cmp    $0x1,%eax
  800448:	75 61                	jne    8004ab <copy_guest_kern_gpa+0x183>
		{
			mapStatus = map_in_guest(guest, prgHdr->p_pa,
									 prgHdr->p_memsz, fileDesc,
									prgHdr->p_filesz, prgHdr->p_offset);
  80044a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80044e:	48 8b 40 08          	mov    0x8(%rax),%rax
		*Proghdr structure. The value of 1 in particular means that the segment type is PT LOAD
		*/

		if (prgHdr->p_type == ELF_PROG_LOAD)
		{
			mapStatus = map_in_guest(guest, prgHdr->p_pa,
  800452:	41 89 c0             	mov    %eax,%r8d
  800455:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800459:	48 8b 78 20          	mov    0x20(%rax),%rdi
  80045d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800461:	48 8b 50 28          	mov    0x28(%rax),%rdx
  800465:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800469:	48 8b 70 18          	mov    0x18(%rax),%rsi
  80046d:	8b 4d ec             	mov    -0x14(%rbp),%ecx
  800470:	8b 85 cc fb ff ff    	mov    -0x434(%rbp),%eax
  800476:	45 89 c1             	mov    %r8d,%r9d
  800479:	49 89 f8             	mov    %rdi,%r8
  80047c:	89 c7                	mov    %eax,%edi
  80047e:	48 b8 43 00 80 00 00 	movabs $0x800043,%rax
  800485:	00 00 00 
  800488:	ff d0                	callq  *%rax
  80048a:	89 45 fc             	mov    %eax,-0x4(%rbp)
									 prgHdr->p_memsz, fileDesc,
									prgHdr->p_filesz, prgHdr->p_offset);
		if (mapStatus < 0)
  80048d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  800491:	79 18                	jns    8004ab <copy_guest_kern_gpa+0x183>
			{
				close(fileDesc);
  800493:	8b 45 ec             	mov    -0x14(%rbp),%eax
  800496:	89 c7                	mov    %eax,%edi
  800498:	48 b8 fd 24 80 00 00 	movabs $0x8024fd,%rax
  80049f:	00 00 00 
  8004a2:	ff d0                	callq  *%rax
				return -E_NO_SYS; //Unimplemented
  8004a4:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
  8004a9:	eb 23                	jmp    8004ce <copy_guest_kern_gpa+0x1a6>

	struct Proghdr *prgHdr = (struct Proghdr *)(fileData + fileHeader->e_phoff); //add offset to data and move tp prgHdr 
	struct Proghdr *endPrgHdr = prgHdr + fileHeader->e_phnum; // add more to prghdr, 32 bit offset
	
	//prgHdr is already initialized
	for (; prgHdr < endPrgHdr; prgHdr++)
  8004ab:	48 83 45 f0 38       	addq   $0x38,-0x10(%rbp)
  8004b0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004b4:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  8004b8:	72 85                	jb     80043f <copy_guest_kern_gpa+0x117>
				close(fileDesc);
				return -E_NO_SYS; //Unimplemented
			}
		}
	}
	close(fileDesc);	//closure upon successful read
  8004ba:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8004bd:	89 c7                	mov    %eax,%edi
  8004bf:	48 b8 fd 24 80 00 00 	movabs $0x8024fd,%rax
  8004c6:	00 00 00 
  8004c9:	ff d0                	callq  *%rax
	return mapStatus;
  8004cb:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
  8004ce:	c9                   	leaveq 
  8004cf:	c3                   	retq   

00000000008004d0 <umain>:

void umain(int argc, char **argv)
{
  8004d0:	55                   	push   %rbp
  8004d1:	48 89 e5             	mov    %rsp,%rbp
  8004d4:	48 83 ec 50          	sub    $0x50,%rsp
  8004d8:	89 7d bc             	mov    %edi,-0x44(%rbp)
  8004db:	48 89 75 b0          	mov    %rsi,-0x50(%rbp)
	int ret;
	envid_t guest;
	char filename_buffer[50]; // buffer to save the path
	int vmdisk_number;
	int r;
	if ((ret = sys_env_mkguest(GUEST_MEM_SZ, JOS_ENTRY)) < 0)
  8004df:	be 00 70 00 00       	mov    $0x7000,%esi
  8004e4:	bf 00 00 00 01       	mov    $0x1000000,%edi
  8004e9:	48 b8 bd 21 80 00 00 	movabs $0x8021bd,%rax
  8004f0:	00 00 00 
  8004f3:	ff d0                	callq  *%rax
  8004f5:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8004f8:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004fc:	79 2c                	jns    80052a <umain+0x5a>
	{
		cprintf("Error creating a guest OS env: %e\n", ret);
  8004fe:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800501:	89 c6                	mov    %eax,%esi
  800503:	48 bf a8 46 80 00 00 	movabs $0x8046a8,%rdi
  80050a:	00 00 00 
  80050d:	b8 00 00 00 00       	mov    $0x0,%eax
  800512:	48 ba 43 09 80 00 00 	movabs $0x800943,%rdx
  800519:	00 00 00 
  80051c:	ff d2                	callq  *%rdx
		exit();
  80051e:	48 b8 e7 06 80 00 00 	movabs $0x8006e7,%rax
  800525:	00 00 00 
  800528:	ff d0                	callq  *%rax
	}
	guest = ret;
  80052a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80052d:	89 45 f8             	mov    %eax,-0x8(%rbp)

	// Copy the guest kernel code into guest phys mem.
	if ((ret = copy_guest_kern_gpa(guest, GUEST_KERN)) < 0)
  800530:	8b 45 f8             	mov    -0x8(%rbp),%eax
  800533:	48 be cb 46 80 00 00 	movabs $0x8046cb,%rsi
  80053a:	00 00 00 
  80053d:	89 c7                	mov    %eax,%edi
  80053f:	48 b8 28 03 80 00 00 	movabs $0x800328,%rax
  800546:	00 00 00 
  800549:	ff d0                	callq  *%rax
  80054b:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80054e:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  800552:	79 2c                	jns    800580 <umain+0xb0>
	{
		cprintf("Error copying page into the guest - %d\n.", ret);
  800554:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800557:	89 c6                	mov    %eax,%esi
  800559:	48 bf d8 46 80 00 00 	movabs $0x8046d8,%rdi
  800560:	00 00 00 
  800563:	b8 00 00 00 00       	mov    $0x0,%eax
  800568:	48 ba 43 09 80 00 00 	movabs $0x800943,%rdx
  80056f:	00 00 00 
  800572:	ff d2                	callq  *%rdx
		exit();
  800574:	48 b8 e7 06 80 00 00 	movabs $0x8006e7,%rax
  80057b:	00 00 00 
  80057e:	ff d0                	callq  *%rax
	}

	// Now copy the bootloader.
	int fd;
	if ((fd = open(GUEST_BOOT, O_RDONLY)) < 0)
  800580:	be 00 00 00 00       	mov    $0x0,%esi
  800585:	48 bf 01 47 80 00 00 	movabs $0x804701,%rdi
  80058c:	00 00 00 
  80058f:	48 b8 f5 2b 80 00 00 	movabs $0x802bf5,%rax
  800596:	00 00 00 
  800599:	ff d0                	callq  *%rax
  80059b:	89 45 f4             	mov    %eax,-0xc(%rbp)
  80059e:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  8005a2:	79 36                	jns    8005da <umain+0x10a>
	{
		cprintf("open %s for read: %e\n", GUEST_BOOT, fd);
  8005a4:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8005a7:	89 c2                	mov    %eax,%edx
  8005a9:	48 be 01 47 80 00 00 	movabs $0x804701,%rsi
  8005b0:	00 00 00 
  8005b3:	48 bf 0b 47 80 00 00 	movabs $0x80470b,%rdi
  8005ba:	00 00 00 
  8005bd:	b8 00 00 00 00       	mov    $0x0,%eax
  8005c2:	48 b9 43 09 80 00 00 	movabs $0x800943,%rcx
  8005c9:	00 00 00 
  8005cc:	ff d1                	callq  *%rcx
		exit();
  8005ce:	48 b8 e7 06 80 00 00 	movabs $0x8006e7,%rax
  8005d5:	00 00 00 
  8005d8:	ff d0                	callq  *%rax
	}

	// sizeof(bootloader) < 512.
	if ((ret = map_in_guest(guest, JOS_ENTRY, 512, fd, 512, 0)) < 0)
  8005da:	8b 55 f4             	mov    -0xc(%rbp),%edx
  8005dd:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8005e0:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8005e6:	41 b8 00 02 00 00    	mov    $0x200,%r8d
  8005ec:	89 d1                	mov    %edx,%ecx
  8005ee:	ba 00 02 00 00       	mov    $0x200,%edx
  8005f3:	be 00 70 00 00       	mov    $0x7000,%esi
  8005f8:	89 c7                	mov    %eax,%edi
  8005fa:	48 b8 43 00 80 00 00 	movabs $0x800043,%rax
  800601:	00 00 00 
  800604:	ff d0                	callq  *%rax
  800606:	89 45 fc             	mov    %eax,-0x4(%rbp)
  800609:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80060d:	79 2c                	jns    80063b <umain+0x16b>
	{
		cprintf("Error mapping bootloader into the guest - %d\n.", ret);
  80060f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800612:	89 c6                	mov    %eax,%esi
  800614:	48 bf 28 47 80 00 00 	movabs $0x804728,%rdi
  80061b:	00 00 00 
  80061e:	b8 00 00 00 00       	mov    $0x0,%eax
  800623:	48 ba 43 09 80 00 00 	movabs $0x800943,%rdx
  80062a:	00 00 00 
  80062d:	ff d2                	callq  *%rdx
		exit();
  80062f:	48 b8 e7 06 80 00 00 	movabs $0x8006e7,%rax
  800636:	00 00 00 
  800639:	ff d0                	callq  *%rax
	}

	cprintf("Create VHD finished\n");
#endif
	// Mark the guest as runnable.
	sys_env_set_status(guest, ENV_RUNNABLE);
  80063b:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80063e:	be 02 00 00 00       	mov    $0x2,%esi
  800643:	89 c7                	mov    %eax,%edi
  800645:	48 b8 1c 1f 80 00 00 	movabs $0x801f1c,%rax
  80064c:	00 00 00 
  80064f:	ff d0                	callq  *%rax
	wait(guest);
  800651:	8b 45 f8             	mov    -0x8(%rbp),%eax
  800654:	89 c7                	mov    %eax,%edi
  800656:	48 b8 07 40 80 00 00 	movabs $0x804007,%rax
  80065d:	00 00 00 
  800660:	ff d0                	callq  *%rax
}
  800662:	c9                   	leaveq 
  800663:	c3                   	retq   

0000000000800664 <libmain>:
  800664:	55                   	push   %rbp
  800665:	48 89 e5             	mov    %rsp,%rbp
  800668:	48 83 ec 10          	sub    $0x10,%rsp
  80066c:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80066f:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  800673:	48 b8 ab 1d 80 00 00 	movabs $0x801dab,%rax
  80067a:	00 00 00 
  80067d:	ff d0                	callq  *%rax
  80067f:	25 ff 03 00 00       	and    $0x3ff,%eax
  800684:	48 98                	cltq   
  800686:	48 69 d0 68 01 00 00 	imul   $0x168,%rax,%rdx
  80068d:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  800694:	00 00 00 
  800697:	48 01 c2             	add    %rax,%rdx
  80069a:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  8006a1:	00 00 00 
  8006a4:	48 89 10             	mov    %rdx,(%rax)
  8006a7:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8006ab:	7e 14                	jle    8006c1 <libmain+0x5d>
  8006ad:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8006b1:	48 8b 10             	mov    (%rax),%rdx
  8006b4:	48 b8 00 60 80 00 00 	movabs $0x806000,%rax
  8006bb:	00 00 00 
  8006be:	48 89 10             	mov    %rdx,(%rax)
  8006c1:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8006c5:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8006c8:	48 89 d6             	mov    %rdx,%rsi
  8006cb:	89 c7                	mov    %eax,%edi
  8006cd:	48 b8 d0 04 80 00 00 	movabs $0x8004d0,%rax
  8006d4:	00 00 00 
  8006d7:	ff d0                	callq  *%rax
  8006d9:	48 b8 e7 06 80 00 00 	movabs $0x8006e7,%rax
  8006e0:	00 00 00 
  8006e3:	ff d0                	callq  *%rax
  8006e5:	c9                   	leaveq 
  8006e6:	c3                   	retq   

00000000008006e7 <exit>:
  8006e7:	55                   	push   %rbp
  8006e8:	48 89 e5             	mov    %rsp,%rbp
  8006eb:	48 b8 48 25 80 00 00 	movabs $0x802548,%rax
  8006f2:	00 00 00 
  8006f5:	ff d0                	callq  *%rax
  8006f7:	bf 00 00 00 00       	mov    $0x0,%edi
  8006fc:	48 b8 67 1d 80 00 00 	movabs $0x801d67,%rax
  800703:	00 00 00 
  800706:	ff d0                	callq  *%rax
  800708:	5d                   	pop    %rbp
  800709:	c3                   	retq   

000000000080070a <_panic>:
  80070a:	55                   	push   %rbp
  80070b:	48 89 e5             	mov    %rsp,%rbp
  80070e:	53                   	push   %rbx
  80070f:	48 81 ec f8 00 00 00 	sub    $0xf8,%rsp
  800716:	48 89 bd 18 ff ff ff 	mov    %rdi,-0xe8(%rbp)
  80071d:	89 b5 14 ff ff ff    	mov    %esi,-0xec(%rbp)
  800723:	48 89 8d 58 ff ff ff 	mov    %rcx,-0xa8(%rbp)
  80072a:	4c 89 85 60 ff ff ff 	mov    %r8,-0xa0(%rbp)
  800731:	4c 89 8d 68 ff ff ff 	mov    %r9,-0x98(%rbp)
  800738:	84 c0                	test   %al,%al
  80073a:	74 23                	je     80075f <_panic+0x55>
  80073c:	0f 29 85 70 ff ff ff 	movaps %xmm0,-0x90(%rbp)
  800743:	0f 29 4d 80          	movaps %xmm1,-0x80(%rbp)
  800747:	0f 29 55 90          	movaps %xmm2,-0x70(%rbp)
  80074b:	0f 29 5d a0          	movaps %xmm3,-0x60(%rbp)
  80074f:	0f 29 65 b0          	movaps %xmm4,-0x50(%rbp)
  800753:	0f 29 6d c0          	movaps %xmm5,-0x40(%rbp)
  800757:	0f 29 75 d0          	movaps %xmm6,-0x30(%rbp)
  80075b:	0f 29 7d e0          	movaps %xmm7,-0x20(%rbp)
  80075f:	48 89 95 08 ff ff ff 	mov    %rdx,-0xf8(%rbp)
  800766:	c7 85 28 ff ff ff 18 	movl   $0x18,-0xd8(%rbp)
  80076d:	00 00 00 
  800770:	c7 85 2c ff ff ff 30 	movl   $0x30,-0xd4(%rbp)
  800777:	00 00 00 
  80077a:	48 8d 45 10          	lea    0x10(%rbp),%rax
  80077e:	48 89 85 30 ff ff ff 	mov    %rax,-0xd0(%rbp)
  800785:	48 8d 85 40 ff ff ff 	lea    -0xc0(%rbp),%rax
  80078c:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  800793:	48 b8 00 60 80 00 00 	movabs $0x806000,%rax
  80079a:	00 00 00 
  80079d:	48 8b 18             	mov    (%rax),%rbx
  8007a0:	48 b8 ab 1d 80 00 00 	movabs $0x801dab,%rax
  8007a7:	00 00 00 
  8007aa:	ff d0                	callq  *%rax
  8007ac:	8b 8d 14 ff ff ff    	mov    -0xec(%rbp),%ecx
  8007b2:	48 8b 95 18 ff ff ff 	mov    -0xe8(%rbp),%rdx
  8007b9:	41 89 c8             	mov    %ecx,%r8d
  8007bc:	48 89 d1             	mov    %rdx,%rcx
  8007bf:	48 89 da             	mov    %rbx,%rdx
  8007c2:	89 c6                	mov    %eax,%esi
  8007c4:	48 bf 68 47 80 00 00 	movabs $0x804768,%rdi
  8007cb:	00 00 00 
  8007ce:	b8 00 00 00 00       	mov    $0x0,%eax
  8007d3:	49 b9 43 09 80 00 00 	movabs $0x800943,%r9
  8007da:	00 00 00 
  8007dd:	41 ff d1             	callq  *%r9
  8007e0:	48 8d 95 28 ff ff ff 	lea    -0xd8(%rbp),%rdx
  8007e7:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  8007ee:	48 89 d6             	mov    %rdx,%rsi
  8007f1:	48 89 c7             	mov    %rax,%rdi
  8007f4:	48 b8 97 08 80 00 00 	movabs $0x800897,%rax
  8007fb:	00 00 00 
  8007fe:	ff d0                	callq  *%rax
  800800:	48 bf 8b 47 80 00 00 	movabs $0x80478b,%rdi
  800807:	00 00 00 
  80080a:	b8 00 00 00 00       	mov    $0x0,%eax
  80080f:	48 ba 43 09 80 00 00 	movabs $0x800943,%rdx
  800816:	00 00 00 
  800819:	ff d2                	callq  *%rdx
  80081b:	cc                   	int3   
  80081c:	eb fd                	jmp    80081b <_panic+0x111>

000000000080081e <putch>:
  80081e:	55                   	push   %rbp
  80081f:	48 89 e5             	mov    %rsp,%rbp
  800822:	48 83 ec 10          	sub    $0x10,%rsp
  800826:	89 7d fc             	mov    %edi,-0x4(%rbp)
  800829:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  80082d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800831:	8b 00                	mov    (%rax),%eax
  800833:	8d 48 01             	lea    0x1(%rax),%ecx
  800836:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80083a:	89 0a                	mov    %ecx,(%rdx)
  80083c:	8b 55 fc             	mov    -0x4(%rbp),%edx
  80083f:	89 d1                	mov    %edx,%ecx
  800841:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  800845:	48 98                	cltq   
  800847:	88 4c 02 08          	mov    %cl,0x8(%rdx,%rax,1)
  80084b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80084f:	8b 00                	mov    (%rax),%eax
  800851:	3d ff 00 00 00       	cmp    $0xff,%eax
  800856:	75 2c                	jne    800884 <putch+0x66>
  800858:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80085c:	8b 00                	mov    (%rax),%eax
  80085e:	48 98                	cltq   
  800860:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  800864:	48 83 c2 08          	add    $0x8,%rdx
  800868:	48 89 c6             	mov    %rax,%rsi
  80086b:	48 89 d7             	mov    %rdx,%rdi
  80086e:	48 b8 df 1c 80 00 00 	movabs $0x801cdf,%rax
  800875:	00 00 00 
  800878:	ff d0                	callq  *%rax
  80087a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80087e:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
  800884:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800888:	8b 40 04             	mov    0x4(%rax),%eax
  80088b:	8d 50 01             	lea    0x1(%rax),%edx
  80088e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800892:	89 50 04             	mov    %edx,0x4(%rax)
  800895:	c9                   	leaveq 
  800896:	c3                   	retq   

0000000000800897 <vcprintf>:
  800897:	55                   	push   %rbp
  800898:	48 89 e5             	mov    %rsp,%rbp
  80089b:	48 81 ec 40 01 00 00 	sub    $0x140,%rsp
  8008a2:	48 89 bd c8 fe ff ff 	mov    %rdi,-0x138(%rbp)
  8008a9:	48 89 b5 c0 fe ff ff 	mov    %rsi,-0x140(%rbp)
  8008b0:	48 8d 85 d8 fe ff ff 	lea    -0x128(%rbp),%rax
  8008b7:	48 8b 95 c0 fe ff ff 	mov    -0x140(%rbp),%rdx
  8008be:	48 8b 0a             	mov    (%rdx),%rcx
  8008c1:	48 89 08             	mov    %rcx,(%rax)
  8008c4:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  8008c8:	48 89 48 08          	mov    %rcx,0x8(%rax)
  8008cc:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  8008d0:	48 89 50 10          	mov    %rdx,0x10(%rax)
  8008d4:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%rbp)
  8008db:	00 00 00 
  8008de:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%rbp)
  8008e5:	00 00 00 
  8008e8:	48 8d 8d d8 fe ff ff 	lea    -0x128(%rbp),%rcx
  8008ef:	48 8b 95 c8 fe ff ff 	mov    -0x138(%rbp),%rdx
  8008f6:	48 8d 85 f0 fe ff ff 	lea    -0x110(%rbp),%rax
  8008fd:	48 89 c6             	mov    %rax,%rsi
  800900:	48 bf 1e 08 80 00 00 	movabs $0x80081e,%rdi
  800907:	00 00 00 
  80090a:	48 b8 f6 0c 80 00 00 	movabs $0x800cf6,%rax
  800911:	00 00 00 
  800914:	ff d0                	callq  *%rax
  800916:	8b 85 f0 fe ff ff    	mov    -0x110(%rbp),%eax
  80091c:	48 98                	cltq   
  80091e:	48 8d 95 f0 fe ff ff 	lea    -0x110(%rbp),%rdx
  800925:	48 83 c2 08          	add    $0x8,%rdx
  800929:	48 89 c6             	mov    %rax,%rsi
  80092c:	48 89 d7             	mov    %rdx,%rdi
  80092f:	48 b8 df 1c 80 00 00 	movabs $0x801cdf,%rax
  800936:	00 00 00 
  800939:	ff d0                	callq  *%rax
  80093b:	8b 85 f4 fe ff ff    	mov    -0x10c(%rbp),%eax
  800941:	c9                   	leaveq 
  800942:	c3                   	retq   

0000000000800943 <cprintf>:
  800943:	55                   	push   %rbp
  800944:	48 89 e5             	mov    %rsp,%rbp
  800947:	48 81 ec 00 01 00 00 	sub    $0x100,%rsp
  80094e:	48 89 b5 58 ff ff ff 	mov    %rsi,-0xa8(%rbp)
  800955:	48 89 95 60 ff ff ff 	mov    %rdx,-0xa0(%rbp)
  80095c:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  800963:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  80096a:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  800971:	84 c0                	test   %al,%al
  800973:	74 20                	je     800995 <cprintf+0x52>
  800975:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  800979:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  80097d:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  800981:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  800985:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  800989:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  80098d:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  800991:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  800995:	48 89 bd 08 ff ff ff 	mov    %rdi,-0xf8(%rbp)
  80099c:	c7 85 30 ff ff ff 08 	movl   $0x8,-0xd0(%rbp)
  8009a3:	00 00 00 
  8009a6:	c7 85 34 ff ff ff 30 	movl   $0x30,-0xcc(%rbp)
  8009ad:	00 00 00 
  8009b0:	48 8d 45 10          	lea    0x10(%rbp),%rax
  8009b4:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  8009bb:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  8009c2:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  8009c9:	48 8d 85 18 ff ff ff 	lea    -0xe8(%rbp),%rax
  8009d0:	48 8d 95 30 ff ff ff 	lea    -0xd0(%rbp),%rdx
  8009d7:	48 8b 0a             	mov    (%rdx),%rcx
  8009da:	48 89 08             	mov    %rcx,(%rax)
  8009dd:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  8009e1:	48 89 48 08          	mov    %rcx,0x8(%rax)
  8009e5:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  8009e9:	48 89 50 10          	mov    %rdx,0x10(%rax)
  8009ed:	48 8d 95 18 ff ff ff 	lea    -0xe8(%rbp),%rdx
  8009f4:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  8009fb:	48 89 d6             	mov    %rdx,%rsi
  8009fe:	48 89 c7             	mov    %rax,%rdi
  800a01:	48 b8 97 08 80 00 00 	movabs $0x800897,%rax
  800a08:	00 00 00 
  800a0b:	ff d0                	callq  *%rax
  800a0d:	89 85 4c ff ff ff    	mov    %eax,-0xb4(%rbp)
  800a13:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
  800a19:	c9                   	leaveq 
  800a1a:	c3                   	retq   

0000000000800a1b <printnum>:
  800a1b:	55                   	push   %rbp
  800a1c:	48 89 e5             	mov    %rsp,%rbp
  800a1f:	53                   	push   %rbx
  800a20:	48 83 ec 38          	sub    $0x38,%rsp
  800a24:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800a28:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  800a2c:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  800a30:	89 4d d4             	mov    %ecx,-0x2c(%rbp)
  800a33:	44 89 45 d0          	mov    %r8d,-0x30(%rbp)
  800a37:	44 89 4d cc          	mov    %r9d,-0x34(%rbp)
  800a3b:	8b 45 d4             	mov    -0x2c(%rbp),%eax
  800a3e:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  800a42:	77 3b                	ja     800a7f <printnum+0x64>
  800a44:	8b 45 d0             	mov    -0x30(%rbp),%eax
  800a47:	44 8d 40 ff          	lea    -0x1(%rax),%r8d
  800a4b:	8b 5d d4             	mov    -0x2c(%rbp),%ebx
  800a4e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800a52:	ba 00 00 00 00       	mov    $0x0,%edx
  800a57:	48 f7 f3             	div    %rbx
  800a5a:	48 89 c2             	mov    %rax,%rdx
  800a5d:	8b 7d cc             	mov    -0x34(%rbp),%edi
  800a60:	8b 4d d4             	mov    -0x2c(%rbp),%ecx
  800a63:	48 8b 75 e0          	mov    -0x20(%rbp),%rsi
  800a67:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800a6b:	41 89 f9             	mov    %edi,%r9d
  800a6e:	48 89 c7             	mov    %rax,%rdi
  800a71:	48 b8 1b 0a 80 00 00 	movabs $0x800a1b,%rax
  800a78:	00 00 00 
  800a7b:	ff d0                	callq  *%rax
  800a7d:	eb 1e                	jmp    800a9d <printnum+0x82>
  800a7f:	eb 12                	jmp    800a93 <printnum+0x78>
  800a81:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  800a85:	8b 55 cc             	mov    -0x34(%rbp),%edx
  800a88:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800a8c:	48 89 ce             	mov    %rcx,%rsi
  800a8f:	89 d7                	mov    %edx,%edi
  800a91:	ff d0                	callq  *%rax
  800a93:	83 6d d0 01          	subl   $0x1,-0x30(%rbp)
  800a97:	83 7d d0 00          	cmpl   $0x0,-0x30(%rbp)
  800a9b:	7f e4                	jg     800a81 <printnum+0x66>
  800a9d:	8b 4d d4             	mov    -0x2c(%rbp),%ecx
  800aa0:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800aa4:	ba 00 00 00 00       	mov    $0x0,%edx
  800aa9:	48 f7 f1             	div    %rcx
  800aac:	48 89 d0             	mov    %rdx,%rax
  800aaf:	48 ba 90 49 80 00 00 	movabs $0x804990,%rdx
  800ab6:	00 00 00 
  800ab9:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
  800abd:	0f be d0             	movsbl %al,%edx
  800ac0:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  800ac4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800ac8:	48 89 ce             	mov    %rcx,%rsi
  800acb:	89 d7                	mov    %edx,%edi
  800acd:	ff d0                	callq  *%rax
  800acf:	48 83 c4 38          	add    $0x38,%rsp
  800ad3:	5b                   	pop    %rbx
  800ad4:	5d                   	pop    %rbp
  800ad5:	c3                   	retq   

0000000000800ad6 <getuint>:
  800ad6:	55                   	push   %rbp
  800ad7:	48 89 e5             	mov    %rsp,%rbp
  800ada:	48 83 ec 1c          	sub    $0x1c,%rsp
  800ade:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800ae2:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  800ae5:	83 7d e4 01          	cmpl   $0x1,-0x1c(%rbp)
  800ae9:	7e 52                	jle    800b3d <getuint+0x67>
  800aeb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800aef:	8b 00                	mov    (%rax),%eax
  800af1:	83 f8 30             	cmp    $0x30,%eax
  800af4:	73 24                	jae    800b1a <getuint+0x44>
  800af6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800afa:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800afe:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b02:	8b 00                	mov    (%rax),%eax
  800b04:	89 c0                	mov    %eax,%eax
  800b06:	48 01 d0             	add    %rdx,%rax
  800b09:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b0d:	8b 12                	mov    (%rdx),%edx
  800b0f:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800b12:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b16:	89 0a                	mov    %ecx,(%rdx)
  800b18:	eb 17                	jmp    800b31 <getuint+0x5b>
  800b1a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b1e:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800b22:	48 89 d0             	mov    %rdx,%rax
  800b25:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800b29:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b2d:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800b31:	48 8b 00             	mov    (%rax),%rax
  800b34:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800b38:	e9 a3 00 00 00       	jmpq   800be0 <getuint+0x10a>
  800b3d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  800b41:	74 4f                	je     800b92 <getuint+0xbc>
  800b43:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b47:	8b 00                	mov    (%rax),%eax
  800b49:	83 f8 30             	cmp    $0x30,%eax
  800b4c:	73 24                	jae    800b72 <getuint+0x9c>
  800b4e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b52:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800b56:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b5a:	8b 00                	mov    (%rax),%eax
  800b5c:	89 c0                	mov    %eax,%eax
  800b5e:	48 01 d0             	add    %rdx,%rax
  800b61:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b65:	8b 12                	mov    (%rdx),%edx
  800b67:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800b6a:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b6e:	89 0a                	mov    %ecx,(%rdx)
  800b70:	eb 17                	jmp    800b89 <getuint+0xb3>
  800b72:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b76:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800b7a:	48 89 d0             	mov    %rdx,%rax
  800b7d:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800b81:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b85:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800b89:	48 8b 00             	mov    (%rax),%rax
  800b8c:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800b90:	eb 4e                	jmp    800be0 <getuint+0x10a>
  800b92:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b96:	8b 00                	mov    (%rax),%eax
  800b98:	83 f8 30             	cmp    $0x30,%eax
  800b9b:	73 24                	jae    800bc1 <getuint+0xeb>
  800b9d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800ba1:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800ba5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800ba9:	8b 00                	mov    (%rax),%eax
  800bab:	89 c0                	mov    %eax,%eax
  800bad:	48 01 d0             	add    %rdx,%rax
  800bb0:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800bb4:	8b 12                	mov    (%rdx),%edx
  800bb6:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800bb9:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800bbd:	89 0a                	mov    %ecx,(%rdx)
  800bbf:	eb 17                	jmp    800bd8 <getuint+0x102>
  800bc1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800bc5:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800bc9:	48 89 d0             	mov    %rdx,%rax
  800bcc:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800bd0:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800bd4:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800bd8:	8b 00                	mov    (%rax),%eax
  800bda:	89 c0                	mov    %eax,%eax
  800bdc:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800be0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800be4:	c9                   	leaveq 
  800be5:	c3                   	retq   

0000000000800be6 <getint>:
  800be6:	55                   	push   %rbp
  800be7:	48 89 e5             	mov    %rsp,%rbp
  800bea:	48 83 ec 1c          	sub    $0x1c,%rsp
  800bee:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800bf2:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  800bf5:	83 7d e4 01          	cmpl   $0x1,-0x1c(%rbp)
  800bf9:	7e 52                	jle    800c4d <getint+0x67>
  800bfb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800bff:	8b 00                	mov    (%rax),%eax
  800c01:	83 f8 30             	cmp    $0x30,%eax
  800c04:	73 24                	jae    800c2a <getint+0x44>
  800c06:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c0a:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800c0e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c12:	8b 00                	mov    (%rax),%eax
  800c14:	89 c0                	mov    %eax,%eax
  800c16:	48 01 d0             	add    %rdx,%rax
  800c19:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c1d:	8b 12                	mov    (%rdx),%edx
  800c1f:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800c22:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c26:	89 0a                	mov    %ecx,(%rdx)
  800c28:	eb 17                	jmp    800c41 <getint+0x5b>
  800c2a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c2e:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800c32:	48 89 d0             	mov    %rdx,%rax
  800c35:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800c39:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c3d:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800c41:	48 8b 00             	mov    (%rax),%rax
  800c44:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800c48:	e9 a3 00 00 00       	jmpq   800cf0 <getint+0x10a>
  800c4d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  800c51:	74 4f                	je     800ca2 <getint+0xbc>
  800c53:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c57:	8b 00                	mov    (%rax),%eax
  800c59:	83 f8 30             	cmp    $0x30,%eax
  800c5c:	73 24                	jae    800c82 <getint+0x9c>
  800c5e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c62:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800c66:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c6a:	8b 00                	mov    (%rax),%eax
  800c6c:	89 c0                	mov    %eax,%eax
  800c6e:	48 01 d0             	add    %rdx,%rax
  800c71:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c75:	8b 12                	mov    (%rdx),%edx
  800c77:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800c7a:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c7e:	89 0a                	mov    %ecx,(%rdx)
  800c80:	eb 17                	jmp    800c99 <getint+0xb3>
  800c82:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c86:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800c8a:	48 89 d0             	mov    %rdx,%rax
  800c8d:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800c91:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c95:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800c99:	48 8b 00             	mov    (%rax),%rax
  800c9c:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800ca0:	eb 4e                	jmp    800cf0 <getint+0x10a>
  800ca2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800ca6:	8b 00                	mov    (%rax),%eax
  800ca8:	83 f8 30             	cmp    $0x30,%eax
  800cab:	73 24                	jae    800cd1 <getint+0xeb>
  800cad:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800cb1:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800cb5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800cb9:	8b 00                	mov    (%rax),%eax
  800cbb:	89 c0                	mov    %eax,%eax
  800cbd:	48 01 d0             	add    %rdx,%rax
  800cc0:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800cc4:	8b 12                	mov    (%rdx),%edx
  800cc6:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800cc9:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800ccd:	89 0a                	mov    %ecx,(%rdx)
  800ccf:	eb 17                	jmp    800ce8 <getint+0x102>
  800cd1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800cd5:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800cd9:	48 89 d0             	mov    %rdx,%rax
  800cdc:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800ce0:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800ce4:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800ce8:	8b 00                	mov    (%rax),%eax
  800cea:	48 98                	cltq   
  800cec:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800cf0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800cf4:	c9                   	leaveq 
  800cf5:	c3                   	retq   

0000000000800cf6 <vprintfmt>:
  800cf6:	55                   	push   %rbp
  800cf7:	48 89 e5             	mov    %rsp,%rbp
  800cfa:	41 54                	push   %r12
  800cfc:	53                   	push   %rbx
  800cfd:	48 83 ec 60          	sub    $0x60,%rsp
  800d01:	48 89 7d a8          	mov    %rdi,-0x58(%rbp)
  800d05:	48 89 75 a0          	mov    %rsi,-0x60(%rbp)
  800d09:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  800d0d:	48 89 4d 90          	mov    %rcx,-0x70(%rbp)
  800d11:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  800d15:	48 8b 55 90          	mov    -0x70(%rbp),%rdx
  800d19:	48 8b 0a             	mov    (%rdx),%rcx
  800d1c:	48 89 08             	mov    %rcx,(%rax)
  800d1f:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  800d23:	48 89 48 08          	mov    %rcx,0x8(%rax)
  800d27:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  800d2b:	48 89 50 10          	mov    %rdx,0x10(%rax)
  800d2f:	eb 17                	jmp    800d48 <vprintfmt+0x52>
  800d31:	85 db                	test   %ebx,%ebx
  800d33:	0f 84 cc 04 00 00    	je     801205 <vprintfmt+0x50f>
  800d39:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800d3d:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800d41:	48 89 d6             	mov    %rdx,%rsi
  800d44:	89 df                	mov    %ebx,%edi
  800d46:	ff d0                	callq  *%rax
  800d48:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800d4c:	48 8d 50 01          	lea    0x1(%rax),%rdx
  800d50:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  800d54:	0f b6 00             	movzbl (%rax),%eax
  800d57:	0f b6 d8             	movzbl %al,%ebx
  800d5a:	83 fb 25             	cmp    $0x25,%ebx
  800d5d:	75 d2                	jne    800d31 <vprintfmt+0x3b>
  800d5f:	c6 45 d3 20          	movb   $0x20,-0x2d(%rbp)
  800d63:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%rbp)
  800d6a:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%rbp)
  800d71:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%rbp)
  800d78:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%rbp)
  800d7f:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800d83:	48 8d 50 01          	lea    0x1(%rax),%rdx
  800d87:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  800d8b:	0f b6 00             	movzbl (%rax),%eax
  800d8e:	0f b6 d8             	movzbl %al,%ebx
  800d91:	8d 43 dd             	lea    -0x23(%rbx),%eax
  800d94:	83 f8 55             	cmp    $0x55,%eax
  800d97:	0f 87 34 04 00 00    	ja     8011d1 <vprintfmt+0x4db>
  800d9d:	89 c0                	mov    %eax,%eax
  800d9f:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  800da6:	00 
  800da7:	48 b8 b8 49 80 00 00 	movabs $0x8049b8,%rax
  800dae:	00 00 00 
  800db1:	48 01 d0             	add    %rdx,%rax
  800db4:	48 8b 00             	mov    (%rax),%rax
  800db7:	ff e0                	jmpq   *%rax
  800db9:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%rbp)
  800dbd:	eb c0                	jmp    800d7f <vprintfmt+0x89>
  800dbf:	c6 45 d3 30          	movb   $0x30,-0x2d(%rbp)
  800dc3:	eb ba                	jmp    800d7f <vprintfmt+0x89>
  800dc5:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%rbp)
  800dcc:	8b 55 d8             	mov    -0x28(%rbp),%edx
  800dcf:	89 d0                	mov    %edx,%eax
  800dd1:	c1 e0 02             	shl    $0x2,%eax
  800dd4:	01 d0                	add    %edx,%eax
  800dd6:	01 c0                	add    %eax,%eax
  800dd8:	01 d8                	add    %ebx,%eax
  800dda:	83 e8 30             	sub    $0x30,%eax
  800ddd:	89 45 d8             	mov    %eax,-0x28(%rbp)
  800de0:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800de4:	0f b6 00             	movzbl (%rax),%eax
  800de7:	0f be d8             	movsbl %al,%ebx
  800dea:	83 fb 2f             	cmp    $0x2f,%ebx
  800ded:	7e 0c                	jle    800dfb <vprintfmt+0x105>
  800def:	83 fb 39             	cmp    $0x39,%ebx
  800df2:	7f 07                	jg     800dfb <vprintfmt+0x105>
  800df4:	48 83 45 98 01       	addq   $0x1,-0x68(%rbp)
  800df9:	eb d1                	jmp    800dcc <vprintfmt+0xd6>
  800dfb:	eb 58                	jmp    800e55 <vprintfmt+0x15f>
  800dfd:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800e00:	83 f8 30             	cmp    $0x30,%eax
  800e03:	73 17                	jae    800e1c <vprintfmt+0x126>
  800e05:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800e09:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800e0c:	89 c0                	mov    %eax,%eax
  800e0e:	48 01 d0             	add    %rdx,%rax
  800e11:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800e14:	83 c2 08             	add    $0x8,%edx
  800e17:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800e1a:	eb 0f                	jmp    800e2b <vprintfmt+0x135>
  800e1c:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800e20:	48 89 d0             	mov    %rdx,%rax
  800e23:	48 83 c2 08          	add    $0x8,%rdx
  800e27:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800e2b:	8b 00                	mov    (%rax),%eax
  800e2d:	89 45 d8             	mov    %eax,-0x28(%rbp)
  800e30:	eb 23                	jmp    800e55 <vprintfmt+0x15f>
  800e32:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800e36:	79 0c                	jns    800e44 <vprintfmt+0x14e>
  800e38:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%rbp)
  800e3f:	e9 3b ff ff ff       	jmpq   800d7f <vprintfmt+0x89>
  800e44:	e9 36 ff ff ff       	jmpq   800d7f <vprintfmt+0x89>
  800e49:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%rbp)
  800e50:	e9 2a ff ff ff       	jmpq   800d7f <vprintfmt+0x89>
  800e55:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800e59:	79 12                	jns    800e6d <vprintfmt+0x177>
  800e5b:	8b 45 d8             	mov    -0x28(%rbp),%eax
  800e5e:	89 45 dc             	mov    %eax,-0x24(%rbp)
  800e61:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%rbp)
  800e68:	e9 12 ff ff ff       	jmpq   800d7f <vprintfmt+0x89>
  800e6d:	e9 0d ff ff ff       	jmpq   800d7f <vprintfmt+0x89>
  800e72:	83 45 e0 01          	addl   $0x1,-0x20(%rbp)
  800e76:	e9 04 ff ff ff       	jmpq   800d7f <vprintfmt+0x89>
  800e7b:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800e7e:	83 f8 30             	cmp    $0x30,%eax
  800e81:	73 17                	jae    800e9a <vprintfmt+0x1a4>
  800e83:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800e87:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800e8a:	89 c0                	mov    %eax,%eax
  800e8c:	48 01 d0             	add    %rdx,%rax
  800e8f:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800e92:	83 c2 08             	add    $0x8,%edx
  800e95:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800e98:	eb 0f                	jmp    800ea9 <vprintfmt+0x1b3>
  800e9a:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800e9e:	48 89 d0             	mov    %rdx,%rax
  800ea1:	48 83 c2 08          	add    $0x8,%rdx
  800ea5:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800ea9:	8b 10                	mov    (%rax),%edx
  800eab:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  800eaf:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800eb3:	48 89 ce             	mov    %rcx,%rsi
  800eb6:	89 d7                	mov    %edx,%edi
  800eb8:	ff d0                	callq  *%rax
  800eba:	e9 40 03 00 00       	jmpq   8011ff <vprintfmt+0x509>
  800ebf:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800ec2:	83 f8 30             	cmp    $0x30,%eax
  800ec5:	73 17                	jae    800ede <vprintfmt+0x1e8>
  800ec7:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800ecb:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800ece:	89 c0                	mov    %eax,%eax
  800ed0:	48 01 d0             	add    %rdx,%rax
  800ed3:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800ed6:	83 c2 08             	add    $0x8,%edx
  800ed9:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800edc:	eb 0f                	jmp    800eed <vprintfmt+0x1f7>
  800ede:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800ee2:	48 89 d0             	mov    %rdx,%rax
  800ee5:	48 83 c2 08          	add    $0x8,%rdx
  800ee9:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800eed:	8b 18                	mov    (%rax),%ebx
  800eef:	85 db                	test   %ebx,%ebx
  800ef1:	79 02                	jns    800ef5 <vprintfmt+0x1ff>
  800ef3:	f7 db                	neg    %ebx
  800ef5:	83 fb 15             	cmp    $0x15,%ebx
  800ef8:	7f 16                	jg     800f10 <vprintfmt+0x21a>
  800efa:	48 b8 e0 48 80 00 00 	movabs $0x8048e0,%rax
  800f01:	00 00 00 
  800f04:	48 63 d3             	movslq %ebx,%rdx
  800f07:	4c 8b 24 d0          	mov    (%rax,%rdx,8),%r12
  800f0b:	4d 85 e4             	test   %r12,%r12
  800f0e:	75 2e                	jne    800f3e <vprintfmt+0x248>
  800f10:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  800f14:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800f18:	89 d9                	mov    %ebx,%ecx
  800f1a:	48 ba a1 49 80 00 00 	movabs $0x8049a1,%rdx
  800f21:	00 00 00 
  800f24:	48 89 c7             	mov    %rax,%rdi
  800f27:	b8 00 00 00 00       	mov    $0x0,%eax
  800f2c:	49 b8 0e 12 80 00 00 	movabs $0x80120e,%r8
  800f33:	00 00 00 
  800f36:	41 ff d0             	callq  *%r8
  800f39:	e9 c1 02 00 00       	jmpq   8011ff <vprintfmt+0x509>
  800f3e:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  800f42:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800f46:	4c 89 e1             	mov    %r12,%rcx
  800f49:	48 ba aa 49 80 00 00 	movabs $0x8049aa,%rdx
  800f50:	00 00 00 
  800f53:	48 89 c7             	mov    %rax,%rdi
  800f56:	b8 00 00 00 00       	mov    $0x0,%eax
  800f5b:	49 b8 0e 12 80 00 00 	movabs $0x80120e,%r8
  800f62:	00 00 00 
  800f65:	41 ff d0             	callq  *%r8
  800f68:	e9 92 02 00 00       	jmpq   8011ff <vprintfmt+0x509>
  800f6d:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800f70:	83 f8 30             	cmp    $0x30,%eax
  800f73:	73 17                	jae    800f8c <vprintfmt+0x296>
  800f75:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800f79:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800f7c:	89 c0                	mov    %eax,%eax
  800f7e:	48 01 d0             	add    %rdx,%rax
  800f81:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800f84:	83 c2 08             	add    $0x8,%edx
  800f87:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800f8a:	eb 0f                	jmp    800f9b <vprintfmt+0x2a5>
  800f8c:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800f90:	48 89 d0             	mov    %rdx,%rax
  800f93:	48 83 c2 08          	add    $0x8,%rdx
  800f97:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800f9b:	4c 8b 20             	mov    (%rax),%r12
  800f9e:	4d 85 e4             	test   %r12,%r12
  800fa1:	75 0a                	jne    800fad <vprintfmt+0x2b7>
  800fa3:	49 bc ad 49 80 00 00 	movabs $0x8049ad,%r12
  800faa:	00 00 00 
  800fad:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800fb1:	7e 3f                	jle    800ff2 <vprintfmt+0x2fc>
  800fb3:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%rbp)
  800fb7:	74 39                	je     800ff2 <vprintfmt+0x2fc>
  800fb9:	8b 45 d8             	mov    -0x28(%rbp),%eax
  800fbc:	48 98                	cltq   
  800fbe:	48 89 c6             	mov    %rax,%rsi
  800fc1:	4c 89 e7             	mov    %r12,%rdi
  800fc4:	48 b8 ba 14 80 00 00 	movabs $0x8014ba,%rax
  800fcb:	00 00 00 
  800fce:	ff d0                	callq  *%rax
  800fd0:	29 45 dc             	sub    %eax,-0x24(%rbp)
  800fd3:	eb 17                	jmp    800fec <vprintfmt+0x2f6>
  800fd5:	0f be 55 d3          	movsbl -0x2d(%rbp),%edx
  800fd9:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  800fdd:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800fe1:	48 89 ce             	mov    %rcx,%rsi
  800fe4:	89 d7                	mov    %edx,%edi
  800fe6:	ff d0                	callq  *%rax
  800fe8:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  800fec:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800ff0:	7f e3                	jg     800fd5 <vprintfmt+0x2df>
  800ff2:	eb 37                	jmp    80102b <vprintfmt+0x335>
  800ff4:	83 7d d4 00          	cmpl   $0x0,-0x2c(%rbp)
  800ff8:	74 1e                	je     801018 <vprintfmt+0x322>
  800ffa:	83 fb 1f             	cmp    $0x1f,%ebx
  800ffd:	7e 05                	jle    801004 <vprintfmt+0x30e>
  800fff:	83 fb 7e             	cmp    $0x7e,%ebx
  801002:	7e 14                	jle    801018 <vprintfmt+0x322>
  801004:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  801008:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80100c:	48 89 d6             	mov    %rdx,%rsi
  80100f:	bf 3f 00 00 00       	mov    $0x3f,%edi
  801014:	ff d0                	callq  *%rax
  801016:	eb 0f                	jmp    801027 <vprintfmt+0x331>
  801018:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  80101c:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  801020:	48 89 d6             	mov    %rdx,%rsi
  801023:	89 df                	mov    %ebx,%edi
  801025:	ff d0                	callq  *%rax
  801027:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  80102b:	4c 89 e0             	mov    %r12,%rax
  80102e:	4c 8d 60 01          	lea    0x1(%rax),%r12
  801032:	0f b6 00             	movzbl (%rax),%eax
  801035:	0f be d8             	movsbl %al,%ebx
  801038:	85 db                	test   %ebx,%ebx
  80103a:	74 10                	je     80104c <vprintfmt+0x356>
  80103c:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  801040:	78 b2                	js     800ff4 <vprintfmt+0x2fe>
  801042:	83 6d d8 01          	subl   $0x1,-0x28(%rbp)
  801046:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  80104a:	79 a8                	jns    800ff4 <vprintfmt+0x2fe>
  80104c:	eb 16                	jmp    801064 <vprintfmt+0x36e>
  80104e:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  801052:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  801056:	48 89 d6             	mov    %rdx,%rsi
  801059:	bf 20 00 00 00       	mov    $0x20,%edi
  80105e:	ff d0                	callq  *%rax
  801060:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  801064:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  801068:	7f e4                	jg     80104e <vprintfmt+0x358>
  80106a:	e9 90 01 00 00       	jmpq   8011ff <vprintfmt+0x509>
  80106f:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  801073:	be 03 00 00 00       	mov    $0x3,%esi
  801078:	48 89 c7             	mov    %rax,%rdi
  80107b:	48 b8 e6 0b 80 00 00 	movabs $0x800be6,%rax
  801082:	00 00 00 
  801085:	ff d0                	callq  *%rax
  801087:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  80108b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80108f:	48 85 c0             	test   %rax,%rax
  801092:	79 1d                	jns    8010b1 <vprintfmt+0x3bb>
  801094:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  801098:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80109c:	48 89 d6             	mov    %rdx,%rsi
  80109f:	bf 2d 00 00 00       	mov    $0x2d,%edi
  8010a4:	ff d0                	callq  *%rax
  8010a6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8010aa:	48 f7 d8             	neg    %rax
  8010ad:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  8010b1:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%rbp)
  8010b8:	e9 d5 00 00 00       	jmpq   801192 <vprintfmt+0x49c>
  8010bd:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  8010c1:	be 03 00 00 00       	mov    $0x3,%esi
  8010c6:	48 89 c7             	mov    %rax,%rdi
  8010c9:	48 b8 d6 0a 80 00 00 	movabs $0x800ad6,%rax
  8010d0:	00 00 00 
  8010d3:	ff d0                	callq  *%rax
  8010d5:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  8010d9:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%rbp)
  8010e0:	e9 ad 00 00 00       	jmpq   801192 <vprintfmt+0x49c>
  8010e5:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  8010e9:	be 03 00 00 00       	mov    $0x3,%esi
  8010ee:	48 89 c7             	mov    %rax,%rdi
  8010f1:	48 b8 d6 0a 80 00 00 	movabs $0x800ad6,%rax
  8010f8:	00 00 00 
  8010fb:	ff d0                	callq  *%rax
  8010fd:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  801101:	c7 45 e4 08 00 00 00 	movl   $0x8,-0x1c(%rbp)
  801108:	e9 85 00 00 00       	jmpq   801192 <vprintfmt+0x49c>
  80110d:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  801111:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  801115:	48 89 d6             	mov    %rdx,%rsi
  801118:	bf 30 00 00 00       	mov    $0x30,%edi
  80111d:	ff d0                	callq  *%rax
  80111f:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  801123:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  801127:	48 89 d6             	mov    %rdx,%rsi
  80112a:	bf 78 00 00 00       	mov    $0x78,%edi
  80112f:	ff d0                	callq  *%rax
  801131:	8b 45 b8             	mov    -0x48(%rbp),%eax
  801134:	83 f8 30             	cmp    $0x30,%eax
  801137:	73 17                	jae    801150 <vprintfmt+0x45a>
  801139:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80113d:	8b 45 b8             	mov    -0x48(%rbp),%eax
  801140:	89 c0                	mov    %eax,%eax
  801142:	48 01 d0             	add    %rdx,%rax
  801145:	8b 55 b8             	mov    -0x48(%rbp),%edx
  801148:	83 c2 08             	add    $0x8,%edx
  80114b:	89 55 b8             	mov    %edx,-0x48(%rbp)
  80114e:	eb 0f                	jmp    80115f <vprintfmt+0x469>
  801150:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  801154:	48 89 d0             	mov    %rdx,%rax
  801157:	48 83 c2 08          	add    $0x8,%rdx
  80115b:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  80115f:	48 8b 00             	mov    (%rax),%rax
  801162:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  801166:	c7 45 e4 10 00 00 00 	movl   $0x10,-0x1c(%rbp)
  80116d:	eb 23                	jmp    801192 <vprintfmt+0x49c>
  80116f:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  801173:	be 03 00 00 00       	mov    $0x3,%esi
  801178:	48 89 c7             	mov    %rax,%rdi
  80117b:	48 b8 d6 0a 80 00 00 	movabs $0x800ad6,%rax
  801182:	00 00 00 
  801185:	ff d0                	callq  *%rax
  801187:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  80118b:	c7 45 e4 10 00 00 00 	movl   $0x10,-0x1c(%rbp)
  801192:	44 0f be 45 d3       	movsbl -0x2d(%rbp),%r8d
  801197:	8b 4d e4             	mov    -0x1c(%rbp),%ecx
  80119a:	8b 7d dc             	mov    -0x24(%rbp),%edi
  80119d:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8011a1:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  8011a5:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8011a9:	45 89 c1             	mov    %r8d,%r9d
  8011ac:	41 89 f8             	mov    %edi,%r8d
  8011af:	48 89 c7             	mov    %rax,%rdi
  8011b2:	48 b8 1b 0a 80 00 00 	movabs $0x800a1b,%rax
  8011b9:	00 00 00 
  8011bc:	ff d0                	callq  *%rax
  8011be:	eb 3f                	jmp    8011ff <vprintfmt+0x509>
  8011c0:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8011c4:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8011c8:	48 89 d6             	mov    %rdx,%rsi
  8011cb:	89 df                	mov    %ebx,%edi
  8011cd:	ff d0                	callq  *%rax
  8011cf:	eb 2e                	jmp    8011ff <vprintfmt+0x509>
  8011d1:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8011d5:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8011d9:	48 89 d6             	mov    %rdx,%rsi
  8011dc:	bf 25 00 00 00       	mov    $0x25,%edi
  8011e1:	ff d0                	callq  *%rax
  8011e3:	48 83 6d 98 01       	subq   $0x1,-0x68(%rbp)
  8011e8:	eb 05                	jmp    8011ef <vprintfmt+0x4f9>
  8011ea:	48 83 6d 98 01       	subq   $0x1,-0x68(%rbp)
  8011ef:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8011f3:	48 83 e8 01          	sub    $0x1,%rax
  8011f7:	0f b6 00             	movzbl (%rax),%eax
  8011fa:	3c 25                	cmp    $0x25,%al
  8011fc:	75 ec                	jne    8011ea <vprintfmt+0x4f4>
  8011fe:	90                   	nop
  8011ff:	90                   	nop
  801200:	e9 43 fb ff ff       	jmpq   800d48 <vprintfmt+0x52>
  801205:	48 83 c4 60          	add    $0x60,%rsp
  801209:	5b                   	pop    %rbx
  80120a:	41 5c                	pop    %r12
  80120c:	5d                   	pop    %rbp
  80120d:	c3                   	retq   

000000000080120e <printfmt>:
  80120e:	55                   	push   %rbp
  80120f:	48 89 e5             	mov    %rsp,%rbp
  801212:	48 81 ec f0 00 00 00 	sub    $0xf0,%rsp
  801219:	48 89 bd 28 ff ff ff 	mov    %rdi,-0xd8(%rbp)
  801220:	48 89 b5 20 ff ff ff 	mov    %rsi,-0xe0(%rbp)
  801227:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  80122e:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  801235:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  80123c:	84 c0                	test   %al,%al
  80123e:	74 20                	je     801260 <printfmt+0x52>
  801240:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  801244:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  801248:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  80124c:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  801250:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  801254:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  801258:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  80125c:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  801260:	48 89 95 18 ff ff ff 	mov    %rdx,-0xe8(%rbp)
  801267:	c7 85 38 ff ff ff 18 	movl   $0x18,-0xc8(%rbp)
  80126e:	00 00 00 
  801271:	c7 85 3c ff ff ff 30 	movl   $0x30,-0xc4(%rbp)
  801278:	00 00 00 
  80127b:	48 8d 45 10          	lea    0x10(%rbp),%rax
  80127f:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  801286:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  80128d:	48 89 85 48 ff ff ff 	mov    %rax,-0xb8(%rbp)
  801294:	48 8d 8d 38 ff ff ff 	lea    -0xc8(%rbp),%rcx
  80129b:	48 8b 95 18 ff ff ff 	mov    -0xe8(%rbp),%rdx
  8012a2:	48 8b b5 20 ff ff ff 	mov    -0xe0(%rbp),%rsi
  8012a9:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  8012b0:	48 89 c7             	mov    %rax,%rdi
  8012b3:	48 b8 f6 0c 80 00 00 	movabs $0x800cf6,%rax
  8012ba:	00 00 00 
  8012bd:	ff d0                	callq  *%rax
  8012bf:	c9                   	leaveq 
  8012c0:	c3                   	retq   

00000000008012c1 <sprintputch>:
  8012c1:	55                   	push   %rbp
  8012c2:	48 89 e5             	mov    %rsp,%rbp
  8012c5:	48 83 ec 10          	sub    $0x10,%rsp
  8012c9:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8012cc:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8012d0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8012d4:	8b 40 10             	mov    0x10(%rax),%eax
  8012d7:	8d 50 01             	lea    0x1(%rax),%edx
  8012da:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8012de:	89 50 10             	mov    %edx,0x10(%rax)
  8012e1:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8012e5:	48 8b 10             	mov    (%rax),%rdx
  8012e8:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8012ec:	48 8b 40 08          	mov    0x8(%rax),%rax
  8012f0:	48 39 c2             	cmp    %rax,%rdx
  8012f3:	73 17                	jae    80130c <sprintputch+0x4b>
  8012f5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8012f9:	48 8b 00             	mov    (%rax),%rax
  8012fc:	48 8d 48 01          	lea    0x1(%rax),%rcx
  801300:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801304:	48 89 0a             	mov    %rcx,(%rdx)
  801307:	8b 55 fc             	mov    -0x4(%rbp),%edx
  80130a:	88 10                	mov    %dl,(%rax)
  80130c:	c9                   	leaveq 
  80130d:	c3                   	retq   

000000000080130e <vsnprintf>:
  80130e:	55                   	push   %rbp
  80130f:	48 89 e5             	mov    %rsp,%rbp
  801312:	48 83 ec 50          	sub    $0x50,%rsp
  801316:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  80131a:	89 75 c4             	mov    %esi,-0x3c(%rbp)
  80131d:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
  801321:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
  801325:	48 8d 45 e8          	lea    -0x18(%rbp),%rax
  801329:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  80132d:	48 8b 0a             	mov    (%rdx),%rcx
  801330:	48 89 08             	mov    %rcx,(%rax)
  801333:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  801337:	48 89 48 08          	mov    %rcx,0x8(%rax)
  80133b:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  80133f:	48 89 50 10          	mov    %rdx,0x10(%rax)
  801343:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  801347:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
  80134b:	8b 45 c4             	mov    -0x3c(%rbp),%eax
  80134e:	48 98                	cltq   
  801350:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  801354:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  801358:	48 01 d0             	add    %rdx,%rax
  80135b:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
  80135f:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%rbp)
  801366:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  80136b:	74 06                	je     801373 <vsnprintf+0x65>
  80136d:	83 7d c4 00          	cmpl   $0x0,-0x3c(%rbp)
  801371:	7f 07                	jg     80137a <vsnprintf+0x6c>
  801373:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  801378:	eb 2f                	jmp    8013a9 <vsnprintf+0x9b>
  80137a:	48 8d 4d e8          	lea    -0x18(%rbp),%rcx
  80137e:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
  801382:	48 8d 45 d0          	lea    -0x30(%rbp),%rax
  801386:	48 89 c6             	mov    %rax,%rsi
  801389:	48 bf c1 12 80 00 00 	movabs $0x8012c1,%rdi
  801390:	00 00 00 
  801393:	48 b8 f6 0c 80 00 00 	movabs $0x800cf6,%rax
  80139a:	00 00 00 
  80139d:	ff d0                	callq  *%rax
  80139f:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8013a3:	c6 00 00             	movb   $0x0,(%rax)
  8013a6:	8b 45 e0             	mov    -0x20(%rbp),%eax
  8013a9:	c9                   	leaveq 
  8013aa:	c3                   	retq   

00000000008013ab <snprintf>:
  8013ab:	55                   	push   %rbp
  8013ac:	48 89 e5             	mov    %rsp,%rbp
  8013af:	48 81 ec 10 01 00 00 	sub    $0x110,%rsp
  8013b6:	48 89 bd 08 ff ff ff 	mov    %rdi,-0xf8(%rbp)
  8013bd:	89 b5 04 ff ff ff    	mov    %esi,-0xfc(%rbp)
  8013c3:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  8013ca:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  8013d1:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  8013d8:	84 c0                	test   %al,%al
  8013da:	74 20                	je     8013fc <snprintf+0x51>
  8013dc:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  8013e0:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  8013e4:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  8013e8:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  8013ec:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  8013f0:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  8013f4:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  8013f8:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  8013fc:	48 89 95 f8 fe ff ff 	mov    %rdx,-0x108(%rbp)
  801403:	c7 85 30 ff ff ff 18 	movl   $0x18,-0xd0(%rbp)
  80140a:	00 00 00 
  80140d:	c7 85 34 ff ff ff 30 	movl   $0x30,-0xcc(%rbp)
  801414:	00 00 00 
  801417:	48 8d 45 10          	lea    0x10(%rbp),%rax
  80141b:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  801422:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  801429:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  801430:	48 8d 85 18 ff ff ff 	lea    -0xe8(%rbp),%rax
  801437:	48 8d 95 30 ff ff ff 	lea    -0xd0(%rbp),%rdx
  80143e:	48 8b 0a             	mov    (%rdx),%rcx
  801441:	48 89 08             	mov    %rcx,(%rax)
  801444:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  801448:	48 89 48 08          	mov    %rcx,0x8(%rax)
  80144c:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  801450:	48 89 50 10          	mov    %rdx,0x10(%rax)
  801454:	48 8d 8d 18 ff ff ff 	lea    -0xe8(%rbp),%rcx
  80145b:	48 8b 95 f8 fe ff ff 	mov    -0x108(%rbp),%rdx
  801462:	8b b5 04 ff ff ff    	mov    -0xfc(%rbp),%esi
  801468:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  80146f:	48 89 c7             	mov    %rax,%rdi
  801472:	48 b8 0e 13 80 00 00 	movabs $0x80130e,%rax
  801479:	00 00 00 
  80147c:	ff d0                	callq  *%rax
  80147e:	89 85 4c ff ff ff    	mov    %eax,-0xb4(%rbp)
  801484:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
  80148a:	c9                   	leaveq 
  80148b:	c3                   	retq   

000000000080148c <strlen>:
  80148c:	55                   	push   %rbp
  80148d:	48 89 e5             	mov    %rsp,%rbp
  801490:	48 83 ec 18          	sub    $0x18,%rsp
  801494:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  801498:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  80149f:	eb 09                	jmp    8014aa <strlen+0x1e>
  8014a1:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8014a5:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  8014aa:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8014ae:	0f b6 00             	movzbl (%rax),%eax
  8014b1:	84 c0                	test   %al,%al
  8014b3:	75 ec                	jne    8014a1 <strlen+0x15>
  8014b5:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8014b8:	c9                   	leaveq 
  8014b9:	c3                   	retq   

00000000008014ba <strnlen>:
  8014ba:	55                   	push   %rbp
  8014bb:	48 89 e5             	mov    %rsp,%rbp
  8014be:	48 83 ec 20          	sub    $0x20,%rsp
  8014c2:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8014c6:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8014ca:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8014d1:	eb 0e                	jmp    8014e1 <strnlen+0x27>
  8014d3:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8014d7:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  8014dc:	48 83 6d e0 01       	subq   $0x1,-0x20(%rbp)
  8014e1:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  8014e6:	74 0b                	je     8014f3 <strnlen+0x39>
  8014e8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8014ec:	0f b6 00             	movzbl (%rax),%eax
  8014ef:	84 c0                	test   %al,%al
  8014f1:	75 e0                	jne    8014d3 <strnlen+0x19>
  8014f3:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8014f6:	c9                   	leaveq 
  8014f7:	c3                   	retq   

00000000008014f8 <strcpy>:
  8014f8:	55                   	push   %rbp
  8014f9:	48 89 e5             	mov    %rsp,%rbp
  8014fc:	48 83 ec 20          	sub    $0x20,%rsp
  801500:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  801504:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  801508:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80150c:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  801510:	90                   	nop
  801511:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801515:	48 8d 50 01          	lea    0x1(%rax),%rdx
  801519:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  80151d:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  801521:	48 8d 4a 01          	lea    0x1(%rdx),%rcx
  801525:	48 89 4d e0          	mov    %rcx,-0x20(%rbp)
  801529:	0f b6 12             	movzbl (%rdx),%edx
  80152c:	88 10                	mov    %dl,(%rax)
  80152e:	0f b6 00             	movzbl (%rax),%eax
  801531:	84 c0                	test   %al,%al
  801533:	75 dc                	jne    801511 <strcpy+0x19>
  801535:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801539:	c9                   	leaveq 
  80153a:	c3                   	retq   

000000000080153b <strcat>:
  80153b:	55                   	push   %rbp
  80153c:	48 89 e5             	mov    %rsp,%rbp
  80153f:	48 83 ec 20          	sub    $0x20,%rsp
  801543:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  801547:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80154b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80154f:	48 89 c7             	mov    %rax,%rdi
  801552:	48 b8 8c 14 80 00 00 	movabs $0x80148c,%rax
  801559:	00 00 00 
  80155c:	ff d0                	callq  *%rax
  80155e:	89 45 fc             	mov    %eax,-0x4(%rbp)
  801561:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801564:	48 63 d0             	movslq %eax,%rdx
  801567:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80156b:	48 01 c2             	add    %rax,%rdx
  80156e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  801572:	48 89 c6             	mov    %rax,%rsi
  801575:	48 89 d7             	mov    %rdx,%rdi
  801578:	48 b8 f8 14 80 00 00 	movabs $0x8014f8,%rax
  80157f:	00 00 00 
  801582:	ff d0                	callq  *%rax
  801584:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801588:	c9                   	leaveq 
  801589:	c3                   	retq   

000000000080158a <strncpy>:
  80158a:	55                   	push   %rbp
  80158b:	48 89 e5             	mov    %rsp,%rbp
  80158e:	48 83 ec 28          	sub    $0x28,%rsp
  801592:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  801596:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80159a:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80159e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8015a2:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  8015a6:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8015ad:	00 
  8015ae:	eb 2a                	jmp    8015da <strncpy+0x50>
  8015b0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8015b4:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8015b8:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8015bc:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8015c0:	0f b6 12             	movzbl (%rdx),%edx
  8015c3:	88 10                	mov    %dl,(%rax)
  8015c5:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8015c9:	0f b6 00             	movzbl (%rax),%eax
  8015cc:	84 c0                	test   %al,%al
  8015ce:	74 05                	je     8015d5 <strncpy+0x4b>
  8015d0:	48 83 45 e0 01       	addq   $0x1,-0x20(%rbp)
  8015d5:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8015da:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8015de:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  8015e2:	72 cc                	jb     8015b0 <strncpy+0x26>
  8015e4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8015e8:	c9                   	leaveq 
  8015e9:	c3                   	retq   

00000000008015ea <strlcpy>:
  8015ea:	55                   	push   %rbp
  8015eb:	48 89 e5             	mov    %rsp,%rbp
  8015ee:	48 83 ec 28          	sub    $0x28,%rsp
  8015f2:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8015f6:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8015fa:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8015fe:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801602:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  801606:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  80160b:	74 3d                	je     80164a <strlcpy+0x60>
  80160d:	eb 1d                	jmp    80162c <strlcpy+0x42>
  80160f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801613:	48 8d 50 01          	lea    0x1(%rax),%rdx
  801617:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  80161b:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  80161f:	48 8d 4a 01          	lea    0x1(%rdx),%rcx
  801623:	48 89 4d e0          	mov    %rcx,-0x20(%rbp)
  801627:	0f b6 12             	movzbl (%rdx),%edx
  80162a:	88 10                	mov    %dl,(%rax)
  80162c:	48 83 6d d8 01       	subq   $0x1,-0x28(%rbp)
  801631:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  801636:	74 0b                	je     801643 <strlcpy+0x59>
  801638:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80163c:	0f b6 00             	movzbl (%rax),%eax
  80163f:	84 c0                	test   %al,%al
  801641:	75 cc                	jne    80160f <strlcpy+0x25>
  801643:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801647:	c6 00 00             	movb   $0x0,(%rax)
  80164a:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80164e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801652:	48 29 c2             	sub    %rax,%rdx
  801655:	48 89 d0             	mov    %rdx,%rax
  801658:	c9                   	leaveq 
  801659:	c3                   	retq   

000000000080165a <strcmp>:
  80165a:	55                   	push   %rbp
  80165b:	48 89 e5             	mov    %rsp,%rbp
  80165e:	48 83 ec 10          	sub    $0x10,%rsp
  801662:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801666:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  80166a:	eb 0a                	jmp    801676 <strcmp+0x1c>
  80166c:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  801671:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
  801676:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80167a:	0f b6 00             	movzbl (%rax),%eax
  80167d:	84 c0                	test   %al,%al
  80167f:	74 12                	je     801693 <strcmp+0x39>
  801681:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801685:	0f b6 10             	movzbl (%rax),%edx
  801688:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80168c:	0f b6 00             	movzbl (%rax),%eax
  80168f:	38 c2                	cmp    %al,%dl
  801691:	74 d9                	je     80166c <strcmp+0x12>
  801693:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801697:	0f b6 00             	movzbl (%rax),%eax
  80169a:	0f b6 d0             	movzbl %al,%edx
  80169d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8016a1:	0f b6 00             	movzbl (%rax),%eax
  8016a4:	0f b6 c0             	movzbl %al,%eax
  8016a7:	29 c2                	sub    %eax,%edx
  8016a9:	89 d0                	mov    %edx,%eax
  8016ab:	c9                   	leaveq 
  8016ac:	c3                   	retq   

00000000008016ad <strncmp>:
  8016ad:	55                   	push   %rbp
  8016ae:	48 89 e5             	mov    %rsp,%rbp
  8016b1:	48 83 ec 18          	sub    $0x18,%rsp
  8016b5:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8016b9:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8016bd:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8016c1:	eb 0f                	jmp    8016d2 <strncmp+0x25>
  8016c3:	48 83 6d e8 01       	subq   $0x1,-0x18(%rbp)
  8016c8:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8016cd:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
  8016d2:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8016d7:	74 1d                	je     8016f6 <strncmp+0x49>
  8016d9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8016dd:	0f b6 00             	movzbl (%rax),%eax
  8016e0:	84 c0                	test   %al,%al
  8016e2:	74 12                	je     8016f6 <strncmp+0x49>
  8016e4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8016e8:	0f b6 10             	movzbl (%rax),%edx
  8016eb:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8016ef:	0f b6 00             	movzbl (%rax),%eax
  8016f2:	38 c2                	cmp    %al,%dl
  8016f4:	74 cd                	je     8016c3 <strncmp+0x16>
  8016f6:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8016fb:	75 07                	jne    801704 <strncmp+0x57>
  8016fd:	b8 00 00 00 00       	mov    $0x0,%eax
  801702:	eb 18                	jmp    80171c <strncmp+0x6f>
  801704:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801708:	0f b6 00             	movzbl (%rax),%eax
  80170b:	0f b6 d0             	movzbl %al,%edx
  80170e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801712:	0f b6 00             	movzbl (%rax),%eax
  801715:	0f b6 c0             	movzbl %al,%eax
  801718:	29 c2                	sub    %eax,%edx
  80171a:	89 d0                	mov    %edx,%eax
  80171c:	c9                   	leaveq 
  80171d:	c3                   	retq   

000000000080171e <strchr>:
  80171e:	55                   	push   %rbp
  80171f:	48 89 e5             	mov    %rsp,%rbp
  801722:	48 83 ec 0c          	sub    $0xc,%rsp
  801726:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80172a:	89 f0                	mov    %esi,%eax
  80172c:	88 45 f4             	mov    %al,-0xc(%rbp)
  80172f:	eb 17                	jmp    801748 <strchr+0x2a>
  801731:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801735:	0f b6 00             	movzbl (%rax),%eax
  801738:	3a 45 f4             	cmp    -0xc(%rbp),%al
  80173b:	75 06                	jne    801743 <strchr+0x25>
  80173d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801741:	eb 15                	jmp    801758 <strchr+0x3a>
  801743:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  801748:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80174c:	0f b6 00             	movzbl (%rax),%eax
  80174f:	84 c0                	test   %al,%al
  801751:	75 de                	jne    801731 <strchr+0x13>
  801753:	b8 00 00 00 00       	mov    $0x0,%eax
  801758:	c9                   	leaveq 
  801759:	c3                   	retq   

000000000080175a <strfind>:
  80175a:	55                   	push   %rbp
  80175b:	48 89 e5             	mov    %rsp,%rbp
  80175e:	48 83 ec 0c          	sub    $0xc,%rsp
  801762:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801766:	89 f0                	mov    %esi,%eax
  801768:	88 45 f4             	mov    %al,-0xc(%rbp)
  80176b:	eb 13                	jmp    801780 <strfind+0x26>
  80176d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801771:	0f b6 00             	movzbl (%rax),%eax
  801774:	3a 45 f4             	cmp    -0xc(%rbp),%al
  801777:	75 02                	jne    80177b <strfind+0x21>
  801779:	eb 10                	jmp    80178b <strfind+0x31>
  80177b:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  801780:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801784:	0f b6 00             	movzbl (%rax),%eax
  801787:	84 c0                	test   %al,%al
  801789:	75 e2                	jne    80176d <strfind+0x13>
  80178b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80178f:	c9                   	leaveq 
  801790:	c3                   	retq   

0000000000801791 <memset>:
  801791:	55                   	push   %rbp
  801792:	48 89 e5             	mov    %rsp,%rbp
  801795:	48 83 ec 18          	sub    $0x18,%rsp
  801799:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80179d:	89 75 f4             	mov    %esi,-0xc(%rbp)
  8017a0:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8017a4:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8017a9:	75 06                	jne    8017b1 <memset+0x20>
  8017ab:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8017af:	eb 69                	jmp    80181a <memset+0x89>
  8017b1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8017b5:	83 e0 03             	and    $0x3,%eax
  8017b8:	48 85 c0             	test   %rax,%rax
  8017bb:	75 48                	jne    801805 <memset+0x74>
  8017bd:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8017c1:	83 e0 03             	and    $0x3,%eax
  8017c4:	48 85 c0             	test   %rax,%rax
  8017c7:	75 3c                	jne    801805 <memset+0x74>
  8017c9:	81 65 f4 ff 00 00 00 	andl   $0xff,-0xc(%rbp)
  8017d0:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8017d3:	c1 e0 18             	shl    $0x18,%eax
  8017d6:	89 c2                	mov    %eax,%edx
  8017d8:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8017db:	c1 e0 10             	shl    $0x10,%eax
  8017de:	09 c2                	or     %eax,%edx
  8017e0:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8017e3:	c1 e0 08             	shl    $0x8,%eax
  8017e6:	09 d0                	or     %edx,%eax
  8017e8:	09 45 f4             	or     %eax,-0xc(%rbp)
  8017eb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8017ef:	48 c1 e8 02          	shr    $0x2,%rax
  8017f3:	48 89 c1             	mov    %rax,%rcx
  8017f6:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8017fa:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8017fd:	48 89 d7             	mov    %rdx,%rdi
  801800:	fc                   	cld    
  801801:	f3 ab                	rep stos %eax,%es:(%rdi)
  801803:	eb 11                	jmp    801816 <memset+0x85>
  801805:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  801809:	8b 45 f4             	mov    -0xc(%rbp),%eax
  80180c:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  801810:	48 89 d7             	mov    %rdx,%rdi
  801813:	fc                   	cld    
  801814:	f3 aa                	rep stos %al,%es:(%rdi)
  801816:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80181a:	c9                   	leaveq 
  80181b:	c3                   	retq   

000000000080181c <memmove>:
  80181c:	55                   	push   %rbp
  80181d:	48 89 e5             	mov    %rsp,%rbp
  801820:	48 83 ec 28          	sub    $0x28,%rsp
  801824:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  801828:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80182c:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801830:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  801834:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  801838:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80183c:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  801840:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801844:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
  801848:	0f 83 88 00 00 00    	jae    8018d6 <memmove+0xba>
  80184e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801852:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  801856:	48 01 d0             	add    %rdx,%rax
  801859:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
  80185d:	76 77                	jbe    8018d6 <memmove+0xba>
  80185f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801863:	48 01 45 f8          	add    %rax,-0x8(%rbp)
  801867:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80186b:	48 01 45 f0          	add    %rax,-0x10(%rbp)
  80186f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801873:	83 e0 03             	and    $0x3,%eax
  801876:	48 85 c0             	test   %rax,%rax
  801879:	75 3b                	jne    8018b6 <memmove+0x9a>
  80187b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80187f:	83 e0 03             	and    $0x3,%eax
  801882:	48 85 c0             	test   %rax,%rax
  801885:	75 2f                	jne    8018b6 <memmove+0x9a>
  801887:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80188b:	83 e0 03             	and    $0x3,%eax
  80188e:	48 85 c0             	test   %rax,%rax
  801891:	75 23                	jne    8018b6 <memmove+0x9a>
  801893:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801897:	48 83 e8 04          	sub    $0x4,%rax
  80189b:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80189f:	48 83 ea 04          	sub    $0x4,%rdx
  8018a3:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8018a7:	48 c1 e9 02          	shr    $0x2,%rcx
  8018ab:	48 89 c7             	mov    %rax,%rdi
  8018ae:	48 89 d6             	mov    %rdx,%rsi
  8018b1:	fd                   	std    
  8018b2:	f3 a5                	rep movsl %ds:(%rsi),%es:(%rdi)
  8018b4:	eb 1d                	jmp    8018d3 <memmove+0xb7>
  8018b6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8018ba:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  8018be:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8018c2:	48 8d 70 ff          	lea    -0x1(%rax),%rsi
  8018c6:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8018ca:	48 89 d7             	mov    %rdx,%rdi
  8018cd:	48 89 c1             	mov    %rax,%rcx
  8018d0:	fd                   	std    
  8018d1:	f3 a4                	rep movsb %ds:(%rsi),%es:(%rdi)
  8018d3:	fc                   	cld    
  8018d4:	eb 57                	jmp    80192d <memmove+0x111>
  8018d6:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8018da:	83 e0 03             	and    $0x3,%eax
  8018dd:	48 85 c0             	test   %rax,%rax
  8018e0:	75 36                	jne    801918 <memmove+0xfc>
  8018e2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8018e6:	83 e0 03             	and    $0x3,%eax
  8018e9:	48 85 c0             	test   %rax,%rax
  8018ec:	75 2a                	jne    801918 <memmove+0xfc>
  8018ee:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8018f2:	83 e0 03             	and    $0x3,%eax
  8018f5:	48 85 c0             	test   %rax,%rax
  8018f8:	75 1e                	jne    801918 <memmove+0xfc>
  8018fa:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8018fe:	48 c1 e8 02          	shr    $0x2,%rax
  801902:	48 89 c1             	mov    %rax,%rcx
  801905:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801909:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80190d:	48 89 c7             	mov    %rax,%rdi
  801910:	48 89 d6             	mov    %rdx,%rsi
  801913:	fc                   	cld    
  801914:	f3 a5                	rep movsl %ds:(%rsi),%es:(%rdi)
  801916:	eb 15                	jmp    80192d <memmove+0x111>
  801918:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80191c:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  801920:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  801924:	48 89 c7             	mov    %rax,%rdi
  801927:	48 89 d6             	mov    %rdx,%rsi
  80192a:	fc                   	cld    
  80192b:	f3 a4                	rep movsb %ds:(%rsi),%es:(%rdi)
  80192d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801931:	c9                   	leaveq 
  801932:	c3                   	retq   

0000000000801933 <memcpy>:
  801933:	55                   	push   %rbp
  801934:	48 89 e5             	mov    %rsp,%rbp
  801937:	48 83 ec 18          	sub    $0x18,%rsp
  80193b:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80193f:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801943:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  801947:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80194b:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
  80194f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801953:	48 89 ce             	mov    %rcx,%rsi
  801956:	48 89 c7             	mov    %rax,%rdi
  801959:	48 b8 1c 18 80 00 00 	movabs $0x80181c,%rax
  801960:	00 00 00 
  801963:	ff d0                	callq  *%rax
  801965:	c9                   	leaveq 
  801966:	c3                   	retq   

0000000000801967 <memcmp>:
  801967:	55                   	push   %rbp
  801968:	48 89 e5             	mov    %rsp,%rbp
  80196b:	48 83 ec 28          	sub    $0x28,%rsp
  80196f:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  801973:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  801977:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80197b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80197f:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  801983:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  801987:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  80198b:	eb 36                	jmp    8019c3 <memcmp+0x5c>
  80198d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801991:	0f b6 10             	movzbl (%rax),%edx
  801994:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801998:	0f b6 00             	movzbl (%rax),%eax
  80199b:	38 c2                	cmp    %al,%dl
  80199d:	74 1a                	je     8019b9 <memcmp+0x52>
  80199f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8019a3:	0f b6 00             	movzbl (%rax),%eax
  8019a6:	0f b6 d0             	movzbl %al,%edx
  8019a9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8019ad:	0f b6 00             	movzbl (%rax),%eax
  8019b0:	0f b6 c0             	movzbl %al,%eax
  8019b3:	29 c2                	sub    %eax,%edx
  8019b5:	89 d0                	mov    %edx,%eax
  8019b7:	eb 20                	jmp    8019d9 <memcmp+0x72>
  8019b9:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8019be:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
  8019c3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8019c7:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  8019cb:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8019cf:	48 85 c0             	test   %rax,%rax
  8019d2:	75 b9                	jne    80198d <memcmp+0x26>
  8019d4:	b8 00 00 00 00       	mov    $0x0,%eax
  8019d9:	c9                   	leaveq 
  8019da:	c3                   	retq   

00000000008019db <memfind>:
  8019db:	55                   	push   %rbp
  8019dc:	48 89 e5             	mov    %rsp,%rbp
  8019df:	48 83 ec 28          	sub    $0x28,%rsp
  8019e3:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8019e7:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  8019ea:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8019ee:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8019f2:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8019f6:	48 01 d0             	add    %rdx,%rax
  8019f9:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8019fd:	eb 15                	jmp    801a14 <memfind+0x39>
  8019ff:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801a03:	0f b6 10             	movzbl (%rax),%edx
  801a06:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  801a09:	38 c2                	cmp    %al,%dl
  801a0b:	75 02                	jne    801a0f <memfind+0x34>
  801a0d:	eb 0f                	jmp    801a1e <memfind+0x43>
  801a0f:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  801a14:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801a18:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
  801a1c:	72 e1                	jb     8019ff <memfind+0x24>
  801a1e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801a22:	c9                   	leaveq 
  801a23:	c3                   	retq   

0000000000801a24 <strtol>:
  801a24:	55                   	push   %rbp
  801a25:	48 89 e5             	mov    %rsp,%rbp
  801a28:	48 83 ec 34          	sub    $0x34,%rsp
  801a2c:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  801a30:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  801a34:	89 55 cc             	mov    %edx,-0x34(%rbp)
  801a37:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  801a3e:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
  801a45:	00 
  801a46:	eb 05                	jmp    801a4d <strtol+0x29>
  801a48:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  801a4d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a51:	0f b6 00             	movzbl (%rax),%eax
  801a54:	3c 20                	cmp    $0x20,%al
  801a56:	74 f0                	je     801a48 <strtol+0x24>
  801a58:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a5c:	0f b6 00             	movzbl (%rax),%eax
  801a5f:	3c 09                	cmp    $0x9,%al
  801a61:	74 e5                	je     801a48 <strtol+0x24>
  801a63:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a67:	0f b6 00             	movzbl (%rax),%eax
  801a6a:	3c 2b                	cmp    $0x2b,%al
  801a6c:	75 07                	jne    801a75 <strtol+0x51>
  801a6e:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  801a73:	eb 17                	jmp    801a8c <strtol+0x68>
  801a75:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a79:	0f b6 00             	movzbl (%rax),%eax
  801a7c:	3c 2d                	cmp    $0x2d,%al
  801a7e:	75 0c                	jne    801a8c <strtol+0x68>
  801a80:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  801a85:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%rbp)
  801a8c:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  801a90:	74 06                	je     801a98 <strtol+0x74>
  801a92:	83 7d cc 10          	cmpl   $0x10,-0x34(%rbp)
  801a96:	75 28                	jne    801ac0 <strtol+0x9c>
  801a98:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a9c:	0f b6 00             	movzbl (%rax),%eax
  801a9f:	3c 30                	cmp    $0x30,%al
  801aa1:	75 1d                	jne    801ac0 <strtol+0x9c>
  801aa3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801aa7:	48 83 c0 01          	add    $0x1,%rax
  801aab:	0f b6 00             	movzbl (%rax),%eax
  801aae:	3c 78                	cmp    $0x78,%al
  801ab0:	75 0e                	jne    801ac0 <strtol+0x9c>
  801ab2:	48 83 45 d8 02       	addq   $0x2,-0x28(%rbp)
  801ab7:	c7 45 cc 10 00 00 00 	movl   $0x10,-0x34(%rbp)
  801abe:	eb 2c                	jmp    801aec <strtol+0xc8>
  801ac0:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  801ac4:	75 19                	jne    801adf <strtol+0xbb>
  801ac6:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801aca:	0f b6 00             	movzbl (%rax),%eax
  801acd:	3c 30                	cmp    $0x30,%al
  801acf:	75 0e                	jne    801adf <strtol+0xbb>
  801ad1:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  801ad6:	c7 45 cc 08 00 00 00 	movl   $0x8,-0x34(%rbp)
  801add:	eb 0d                	jmp    801aec <strtol+0xc8>
  801adf:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  801ae3:	75 07                	jne    801aec <strtol+0xc8>
  801ae5:	c7 45 cc 0a 00 00 00 	movl   $0xa,-0x34(%rbp)
  801aec:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801af0:	0f b6 00             	movzbl (%rax),%eax
  801af3:	3c 2f                	cmp    $0x2f,%al
  801af5:	7e 1d                	jle    801b14 <strtol+0xf0>
  801af7:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801afb:	0f b6 00             	movzbl (%rax),%eax
  801afe:	3c 39                	cmp    $0x39,%al
  801b00:	7f 12                	jg     801b14 <strtol+0xf0>
  801b02:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b06:	0f b6 00             	movzbl (%rax),%eax
  801b09:	0f be c0             	movsbl %al,%eax
  801b0c:	83 e8 30             	sub    $0x30,%eax
  801b0f:	89 45 ec             	mov    %eax,-0x14(%rbp)
  801b12:	eb 4e                	jmp    801b62 <strtol+0x13e>
  801b14:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b18:	0f b6 00             	movzbl (%rax),%eax
  801b1b:	3c 60                	cmp    $0x60,%al
  801b1d:	7e 1d                	jle    801b3c <strtol+0x118>
  801b1f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b23:	0f b6 00             	movzbl (%rax),%eax
  801b26:	3c 7a                	cmp    $0x7a,%al
  801b28:	7f 12                	jg     801b3c <strtol+0x118>
  801b2a:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b2e:	0f b6 00             	movzbl (%rax),%eax
  801b31:	0f be c0             	movsbl %al,%eax
  801b34:	83 e8 57             	sub    $0x57,%eax
  801b37:	89 45 ec             	mov    %eax,-0x14(%rbp)
  801b3a:	eb 26                	jmp    801b62 <strtol+0x13e>
  801b3c:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b40:	0f b6 00             	movzbl (%rax),%eax
  801b43:	3c 40                	cmp    $0x40,%al
  801b45:	7e 48                	jle    801b8f <strtol+0x16b>
  801b47:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b4b:	0f b6 00             	movzbl (%rax),%eax
  801b4e:	3c 5a                	cmp    $0x5a,%al
  801b50:	7f 3d                	jg     801b8f <strtol+0x16b>
  801b52:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b56:	0f b6 00             	movzbl (%rax),%eax
  801b59:	0f be c0             	movsbl %al,%eax
  801b5c:	83 e8 37             	sub    $0x37,%eax
  801b5f:	89 45 ec             	mov    %eax,-0x14(%rbp)
  801b62:	8b 45 ec             	mov    -0x14(%rbp),%eax
  801b65:	3b 45 cc             	cmp    -0x34(%rbp),%eax
  801b68:	7c 02                	jl     801b6c <strtol+0x148>
  801b6a:	eb 23                	jmp    801b8f <strtol+0x16b>
  801b6c:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  801b71:	8b 45 cc             	mov    -0x34(%rbp),%eax
  801b74:	48 98                	cltq   
  801b76:	48 0f af 45 f0       	imul   -0x10(%rbp),%rax
  801b7b:	48 89 c2             	mov    %rax,%rdx
  801b7e:	8b 45 ec             	mov    -0x14(%rbp),%eax
  801b81:	48 98                	cltq   
  801b83:	48 01 d0             	add    %rdx,%rax
  801b86:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  801b8a:	e9 5d ff ff ff       	jmpq   801aec <strtol+0xc8>
  801b8f:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  801b94:	74 0b                	je     801ba1 <strtol+0x17d>
  801b96:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801b9a:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  801b9e:	48 89 10             	mov    %rdx,(%rax)
  801ba1:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  801ba5:	74 09                	je     801bb0 <strtol+0x18c>
  801ba7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801bab:	48 f7 d8             	neg    %rax
  801bae:	eb 04                	jmp    801bb4 <strtol+0x190>
  801bb0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801bb4:	c9                   	leaveq 
  801bb5:	c3                   	retq   

0000000000801bb6 <strstr>:
  801bb6:	55                   	push   %rbp
  801bb7:	48 89 e5             	mov    %rsp,%rbp
  801bba:	48 83 ec 30          	sub    $0x30,%rsp
  801bbe:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  801bc2:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  801bc6:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801bca:	48 8d 50 01          	lea    0x1(%rax),%rdx
  801bce:	48 89 55 d0          	mov    %rdx,-0x30(%rbp)
  801bd2:	0f b6 00             	movzbl (%rax),%eax
  801bd5:	88 45 ff             	mov    %al,-0x1(%rbp)
  801bd8:	80 7d ff 00          	cmpb   $0x0,-0x1(%rbp)
  801bdc:	75 06                	jne    801be4 <strstr+0x2e>
  801bde:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801be2:	eb 6b                	jmp    801c4f <strstr+0x99>
  801be4:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801be8:	48 89 c7             	mov    %rax,%rdi
  801beb:	48 b8 8c 14 80 00 00 	movabs $0x80148c,%rax
  801bf2:	00 00 00 
  801bf5:	ff d0                	callq  *%rax
  801bf7:	48 98                	cltq   
  801bf9:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  801bfd:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801c01:	48 8d 50 01          	lea    0x1(%rax),%rdx
  801c05:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801c09:	0f b6 00             	movzbl (%rax),%eax
  801c0c:	88 45 ef             	mov    %al,-0x11(%rbp)
  801c0f:	80 7d ef 00          	cmpb   $0x0,-0x11(%rbp)
  801c13:	75 07                	jne    801c1c <strstr+0x66>
  801c15:	b8 00 00 00 00       	mov    $0x0,%eax
  801c1a:	eb 33                	jmp    801c4f <strstr+0x99>
  801c1c:	0f b6 45 ef          	movzbl -0x11(%rbp),%eax
  801c20:	3a 45 ff             	cmp    -0x1(%rbp),%al
  801c23:	75 d8                	jne    801bfd <strstr+0x47>
  801c25:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801c29:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  801c2d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801c31:	48 89 ce             	mov    %rcx,%rsi
  801c34:	48 89 c7             	mov    %rax,%rdi
  801c37:	48 b8 ad 16 80 00 00 	movabs $0x8016ad,%rax
  801c3e:	00 00 00 
  801c41:	ff d0                	callq  *%rax
  801c43:	85 c0                	test   %eax,%eax
  801c45:	75 b6                	jne    801bfd <strstr+0x47>
  801c47:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801c4b:	48 83 e8 01          	sub    $0x1,%rax
  801c4f:	c9                   	leaveq 
  801c50:	c3                   	retq   

0000000000801c51 <syscall>:
  801c51:	55                   	push   %rbp
  801c52:	48 89 e5             	mov    %rsp,%rbp
  801c55:	53                   	push   %rbx
  801c56:	48 83 ec 48          	sub    $0x48,%rsp
  801c5a:	89 7d dc             	mov    %edi,-0x24(%rbp)
  801c5d:	89 75 d8             	mov    %esi,-0x28(%rbp)
  801c60:	48 89 55 d0          	mov    %rdx,-0x30(%rbp)
  801c64:	48 89 4d c8          	mov    %rcx,-0x38(%rbp)
  801c68:	4c 89 45 c0          	mov    %r8,-0x40(%rbp)
  801c6c:	4c 89 4d b8          	mov    %r9,-0x48(%rbp)
  801c70:	8b 45 dc             	mov    -0x24(%rbp),%eax
  801c73:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  801c77:	48 8b 4d c8          	mov    -0x38(%rbp),%rcx
  801c7b:	4c 8b 45 c0          	mov    -0x40(%rbp),%r8
  801c7f:	48 8b 7d b8          	mov    -0x48(%rbp),%rdi
  801c83:	48 8b 75 10          	mov    0x10(%rbp),%rsi
  801c87:	4c 89 c3             	mov    %r8,%rbx
  801c8a:	cd 30                	int    $0x30
  801c8c:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  801c90:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  801c94:	74 3e                	je     801cd4 <syscall+0x83>
  801c96:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  801c9b:	7e 37                	jle    801cd4 <syscall+0x83>
  801c9d:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  801ca1:	8b 45 dc             	mov    -0x24(%rbp),%eax
  801ca4:	49 89 d0             	mov    %rdx,%r8
  801ca7:	89 c1                	mov    %eax,%ecx
  801ca9:	48 ba 68 4c 80 00 00 	movabs $0x804c68,%rdx
  801cb0:	00 00 00 
  801cb3:	be 24 00 00 00       	mov    $0x24,%esi
  801cb8:	48 bf 85 4c 80 00 00 	movabs $0x804c85,%rdi
  801cbf:	00 00 00 
  801cc2:	b8 00 00 00 00       	mov    $0x0,%eax
  801cc7:	49 b9 0a 07 80 00 00 	movabs $0x80070a,%r9
  801cce:	00 00 00 
  801cd1:	41 ff d1             	callq  *%r9
  801cd4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801cd8:	48 83 c4 48          	add    $0x48,%rsp
  801cdc:	5b                   	pop    %rbx
  801cdd:	5d                   	pop    %rbp
  801cde:	c3                   	retq   

0000000000801cdf <sys_cputs>:
  801cdf:	55                   	push   %rbp
  801ce0:	48 89 e5             	mov    %rsp,%rbp
  801ce3:	48 83 ec 20          	sub    $0x20,%rsp
  801ce7:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801ceb:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801cef:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801cf3:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801cf7:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801cfe:	00 
  801cff:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801d05:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801d0b:	48 89 d1             	mov    %rdx,%rcx
  801d0e:	48 89 c2             	mov    %rax,%rdx
  801d11:	be 00 00 00 00       	mov    $0x0,%esi
  801d16:	bf 00 00 00 00       	mov    $0x0,%edi
  801d1b:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  801d22:	00 00 00 
  801d25:	ff d0                	callq  *%rax
  801d27:	c9                   	leaveq 
  801d28:	c3                   	retq   

0000000000801d29 <sys_cgetc>:
  801d29:	55                   	push   %rbp
  801d2a:	48 89 e5             	mov    %rsp,%rbp
  801d2d:	48 83 ec 10          	sub    $0x10,%rsp
  801d31:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801d38:	00 
  801d39:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801d3f:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801d45:	b9 00 00 00 00       	mov    $0x0,%ecx
  801d4a:	ba 00 00 00 00       	mov    $0x0,%edx
  801d4f:	be 00 00 00 00       	mov    $0x0,%esi
  801d54:	bf 01 00 00 00       	mov    $0x1,%edi
  801d59:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  801d60:	00 00 00 
  801d63:	ff d0                	callq  *%rax
  801d65:	c9                   	leaveq 
  801d66:	c3                   	retq   

0000000000801d67 <sys_env_destroy>:
  801d67:	55                   	push   %rbp
  801d68:	48 89 e5             	mov    %rsp,%rbp
  801d6b:	48 83 ec 10          	sub    $0x10,%rsp
  801d6f:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801d72:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801d75:	48 98                	cltq   
  801d77:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801d7e:	00 
  801d7f:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801d85:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801d8b:	b9 00 00 00 00       	mov    $0x0,%ecx
  801d90:	48 89 c2             	mov    %rax,%rdx
  801d93:	be 01 00 00 00       	mov    $0x1,%esi
  801d98:	bf 03 00 00 00       	mov    $0x3,%edi
  801d9d:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  801da4:	00 00 00 
  801da7:	ff d0                	callq  *%rax
  801da9:	c9                   	leaveq 
  801daa:	c3                   	retq   

0000000000801dab <sys_getenvid>:
  801dab:	55                   	push   %rbp
  801dac:	48 89 e5             	mov    %rsp,%rbp
  801daf:	48 83 ec 10          	sub    $0x10,%rsp
  801db3:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801dba:	00 
  801dbb:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801dc1:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801dc7:	b9 00 00 00 00       	mov    $0x0,%ecx
  801dcc:	ba 00 00 00 00       	mov    $0x0,%edx
  801dd1:	be 00 00 00 00       	mov    $0x0,%esi
  801dd6:	bf 02 00 00 00       	mov    $0x2,%edi
  801ddb:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  801de2:	00 00 00 
  801de5:	ff d0                	callq  *%rax
  801de7:	c9                   	leaveq 
  801de8:	c3                   	retq   

0000000000801de9 <sys_yield>:
  801de9:	55                   	push   %rbp
  801dea:	48 89 e5             	mov    %rsp,%rbp
  801ded:	48 83 ec 10          	sub    $0x10,%rsp
  801df1:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801df8:	00 
  801df9:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801dff:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801e05:	b9 00 00 00 00       	mov    $0x0,%ecx
  801e0a:	ba 00 00 00 00       	mov    $0x0,%edx
  801e0f:	be 00 00 00 00       	mov    $0x0,%esi
  801e14:	bf 0b 00 00 00       	mov    $0xb,%edi
  801e19:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  801e20:	00 00 00 
  801e23:	ff d0                	callq  *%rax
  801e25:	c9                   	leaveq 
  801e26:	c3                   	retq   

0000000000801e27 <sys_page_alloc>:
  801e27:	55                   	push   %rbp
  801e28:	48 89 e5             	mov    %rsp,%rbp
  801e2b:	48 83 ec 20          	sub    $0x20,%rsp
  801e2f:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801e32:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801e36:	89 55 f8             	mov    %edx,-0x8(%rbp)
  801e39:	8b 45 f8             	mov    -0x8(%rbp),%eax
  801e3c:	48 63 c8             	movslq %eax,%rcx
  801e3f:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801e43:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801e46:	48 98                	cltq   
  801e48:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801e4f:	00 
  801e50:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801e56:	49 89 c8             	mov    %rcx,%r8
  801e59:	48 89 d1             	mov    %rdx,%rcx
  801e5c:	48 89 c2             	mov    %rax,%rdx
  801e5f:	be 01 00 00 00       	mov    $0x1,%esi
  801e64:	bf 04 00 00 00       	mov    $0x4,%edi
  801e69:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  801e70:	00 00 00 
  801e73:	ff d0                	callq  *%rax
  801e75:	c9                   	leaveq 
  801e76:	c3                   	retq   

0000000000801e77 <sys_page_map>:
  801e77:	55                   	push   %rbp
  801e78:	48 89 e5             	mov    %rsp,%rbp
  801e7b:	48 83 ec 30          	sub    $0x30,%rsp
  801e7f:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801e82:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801e86:	89 55 f8             	mov    %edx,-0x8(%rbp)
  801e89:	48 89 4d e8          	mov    %rcx,-0x18(%rbp)
  801e8d:	44 89 45 e4          	mov    %r8d,-0x1c(%rbp)
  801e91:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  801e94:	48 63 c8             	movslq %eax,%rcx
  801e97:	48 8b 7d e8          	mov    -0x18(%rbp),%rdi
  801e9b:	8b 45 f8             	mov    -0x8(%rbp),%eax
  801e9e:	48 63 f0             	movslq %eax,%rsi
  801ea1:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801ea5:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801ea8:	48 98                	cltq   
  801eaa:	48 89 0c 24          	mov    %rcx,(%rsp)
  801eae:	49 89 f9             	mov    %rdi,%r9
  801eb1:	49 89 f0             	mov    %rsi,%r8
  801eb4:	48 89 d1             	mov    %rdx,%rcx
  801eb7:	48 89 c2             	mov    %rax,%rdx
  801eba:	be 01 00 00 00       	mov    $0x1,%esi
  801ebf:	bf 05 00 00 00       	mov    $0x5,%edi
  801ec4:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  801ecb:	00 00 00 
  801ece:	ff d0                	callq  *%rax
  801ed0:	c9                   	leaveq 
  801ed1:	c3                   	retq   

0000000000801ed2 <sys_page_unmap>:
  801ed2:	55                   	push   %rbp
  801ed3:	48 89 e5             	mov    %rsp,%rbp
  801ed6:	48 83 ec 20          	sub    $0x20,%rsp
  801eda:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801edd:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801ee1:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801ee5:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801ee8:	48 98                	cltq   
  801eea:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801ef1:	00 
  801ef2:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801ef8:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801efe:	48 89 d1             	mov    %rdx,%rcx
  801f01:	48 89 c2             	mov    %rax,%rdx
  801f04:	be 01 00 00 00       	mov    $0x1,%esi
  801f09:	bf 06 00 00 00       	mov    $0x6,%edi
  801f0e:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  801f15:	00 00 00 
  801f18:	ff d0                	callq  *%rax
  801f1a:	c9                   	leaveq 
  801f1b:	c3                   	retq   

0000000000801f1c <sys_env_set_status>:
  801f1c:	55                   	push   %rbp
  801f1d:	48 89 e5             	mov    %rsp,%rbp
  801f20:	48 83 ec 10          	sub    $0x10,%rsp
  801f24:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801f27:	89 75 f8             	mov    %esi,-0x8(%rbp)
  801f2a:	8b 45 f8             	mov    -0x8(%rbp),%eax
  801f2d:	48 63 d0             	movslq %eax,%rdx
  801f30:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801f33:	48 98                	cltq   
  801f35:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801f3c:	00 
  801f3d:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801f43:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801f49:	48 89 d1             	mov    %rdx,%rcx
  801f4c:	48 89 c2             	mov    %rax,%rdx
  801f4f:	be 01 00 00 00       	mov    $0x1,%esi
  801f54:	bf 08 00 00 00       	mov    $0x8,%edi
  801f59:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  801f60:	00 00 00 
  801f63:	ff d0                	callq  *%rax
  801f65:	c9                   	leaveq 
  801f66:	c3                   	retq   

0000000000801f67 <sys_env_set_trapframe>:
  801f67:	55                   	push   %rbp
  801f68:	48 89 e5             	mov    %rsp,%rbp
  801f6b:	48 83 ec 20          	sub    $0x20,%rsp
  801f6f:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801f72:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801f76:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801f7a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801f7d:	48 98                	cltq   
  801f7f:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801f86:	00 
  801f87:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801f8d:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801f93:	48 89 d1             	mov    %rdx,%rcx
  801f96:	48 89 c2             	mov    %rax,%rdx
  801f99:	be 01 00 00 00       	mov    $0x1,%esi
  801f9e:	bf 09 00 00 00       	mov    $0x9,%edi
  801fa3:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  801faa:	00 00 00 
  801fad:	ff d0                	callq  *%rax
  801faf:	c9                   	leaveq 
  801fb0:	c3                   	retq   

0000000000801fb1 <sys_env_set_pgfault_upcall>:
  801fb1:	55                   	push   %rbp
  801fb2:	48 89 e5             	mov    %rsp,%rbp
  801fb5:	48 83 ec 20          	sub    $0x20,%rsp
  801fb9:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801fbc:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801fc0:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801fc4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801fc7:	48 98                	cltq   
  801fc9:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801fd0:	00 
  801fd1:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801fd7:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801fdd:	48 89 d1             	mov    %rdx,%rcx
  801fe0:	48 89 c2             	mov    %rax,%rdx
  801fe3:	be 01 00 00 00       	mov    $0x1,%esi
  801fe8:	bf 0a 00 00 00       	mov    $0xa,%edi
  801fed:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  801ff4:	00 00 00 
  801ff7:	ff d0                	callq  *%rax
  801ff9:	c9                   	leaveq 
  801ffa:	c3                   	retq   

0000000000801ffb <sys_ipc_try_send>:
  801ffb:	55                   	push   %rbp
  801ffc:	48 89 e5             	mov    %rsp,%rbp
  801fff:	48 83 ec 20          	sub    $0x20,%rsp
  802003:	89 7d fc             	mov    %edi,-0x4(%rbp)
  802006:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  80200a:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  80200e:	89 4d f8             	mov    %ecx,-0x8(%rbp)
  802011:	8b 45 f8             	mov    -0x8(%rbp),%eax
  802014:	48 63 f0             	movslq %eax,%rsi
  802017:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  80201b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80201e:	48 98                	cltq   
  802020:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  802024:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  80202b:	00 
  80202c:	49 89 f1             	mov    %rsi,%r9
  80202f:	49 89 c8             	mov    %rcx,%r8
  802032:	48 89 d1             	mov    %rdx,%rcx
  802035:	48 89 c2             	mov    %rax,%rdx
  802038:	be 00 00 00 00       	mov    $0x0,%esi
  80203d:	bf 0c 00 00 00       	mov    $0xc,%edi
  802042:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  802049:	00 00 00 
  80204c:	ff d0                	callq  *%rax
  80204e:	c9                   	leaveq 
  80204f:	c3                   	retq   

0000000000802050 <sys_ipc_recv>:
  802050:	55                   	push   %rbp
  802051:	48 89 e5             	mov    %rsp,%rbp
  802054:	48 83 ec 10          	sub    $0x10,%rsp
  802058:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80205c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802060:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  802067:	00 
  802068:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  80206e:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  802074:	b9 00 00 00 00       	mov    $0x0,%ecx
  802079:	48 89 c2             	mov    %rax,%rdx
  80207c:	be 01 00 00 00       	mov    $0x1,%esi
  802081:	bf 0d 00 00 00       	mov    $0xd,%edi
  802086:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  80208d:	00 00 00 
  802090:	ff d0                	callq  *%rax
  802092:	c9                   	leaveq 
  802093:	c3                   	retq   

0000000000802094 <sys_time_msec>:
  802094:	55                   	push   %rbp
  802095:	48 89 e5             	mov    %rsp,%rbp
  802098:	48 83 ec 10          	sub    $0x10,%rsp
  80209c:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  8020a3:	00 
  8020a4:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8020aa:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  8020b0:	b9 00 00 00 00       	mov    $0x0,%ecx
  8020b5:	ba 00 00 00 00       	mov    $0x0,%edx
  8020ba:	be 00 00 00 00       	mov    $0x0,%esi
  8020bf:	bf 0e 00 00 00       	mov    $0xe,%edi
  8020c4:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  8020cb:	00 00 00 
  8020ce:	ff d0                	callq  *%rax
  8020d0:	c9                   	leaveq 
  8020d1:	c3                   	retq   

00000000008020d2 <sys_net_transmit>:
  8020d2:	55                   	push   %rbp
  8020d3:	48 89 e5             	mov    %rsp,%rbp
  8020d6:	48 83 ec 20          	sub    $0x20,%rsp
  8020da:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8020de:	89 75 f4             	mov    %esi,-0xc(%rbp)
  8020e1:	8b 55 f4             	mov    -0xc(%rbp),%edx
  8020e4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8020e8:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  8020ef:	00 
  8020f0:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8020f6:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  8020fc:	48 89 d1             	mov    %rdx,%rcx
  8020ff:	48 89 c2             	mov    %rax,%rdx
  802102:	be 00 00 00 00       	mov    $0x0,%esi
  802107:	bf 0f 00 00 00       	mov    $0xf,%edi
  80210c:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  802113:	00 00 00 
  802116:	ff d0                	callq  *%rax
  802118:	c9                   	leaveq 
  802119:	c3                   	retq   

000000000080211a <sys_net_receive>:
  80211a:	55                   	push   %rbp
  80211b:	48 89 e5             	mov    %rsp,%rbp
  80211e:	48 83 ec 20          	sub    $0x20,%rsp
  802122:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802126:	89 75 f4             	mov    %esi,-0xc(%rbp)
  802129:	8b 55 f4             	mov    -0xc(%rbp),%edx
  80212c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802130:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  802137:	00 
  802138:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  80213e:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  802144:	48 89 d1             	mov    %rdx,%rcx
  802147:	48 89 c2             	mov    %rax,%rdx
  80214a:	be 00 00 00 00       	mov    $0x0,%esi
  80214f:	bf 10 00 00 00       	mov    $0x10,%edi
  802154:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  80215b:	00 00 00 
  80215e:	ff d0                	callq  *%rax
  802160:	c9                   	leaveq 
  802161:	c3                   	retq   

0000000000802162 <sys_ept_map>:
  802162:	55                   	push   %rbp
  802163:	48 89 e5             	mov    %rsp,%rbp
  802166:	48 83 ec 30          	sub    $0x30,%rsp
  80216a:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80216d:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  802171:	89 55 f8             	mov    %edx,-0x8(%rbp)
  802174:	48 89 4d e8          	mov    %rcx,-0x18(%rbp)
  802178:	44 89 45 e4          	mov    %r8d,-0x1c(%rbp)
  80217c:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  80217f:	48 63 c8             	movslq %eax,%rcx
  802182:	48 8b 7d e8          	mov    -0x18(%rbp),%rdi
  802186:	8b 45 f8             	mov    -0x8(%rbp),%eax
  802189:	48 63 f0             	movslq %eax,%rsi
  80218c:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  802190:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802193:	48 98                	cltq   
  802195:	48 89 0c 24          	mov    %rcx,(%rsp)
  802199:	49 89 f9             	mov    %rdi,%r9
  80219c:	49 89 f0             	mov    %rsi,%r8
  80219f:	48 89 d1             	mov    %rdx,%rcx
  8021a2:	48 89 c2             	mov    %rax,%rdx
  8021a5:	be 00 00 00 00       	mov    $0x0,%esi
  8021aa:	bf 11 00 00 00       	mov    $0x11,%edi
  8021af:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  8021b6:	00 00 00 
  8021b9:	ff d0                	callq  *%rax
  8021bb:	c9                   	leaveq 
  8021bc:	c3                   	retq   

00000000008021bd <sys_env_mkguest>:
  8021bd:	55                   	push   %rbp
  8021be:	48 89 e5             	mov    %rsp,%rbp
  8021c1:	48 83 ec 20          	sub    $0x20,%rsp
  8021c5:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8021c9:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8021cd:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8021d1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8021d5:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  8021dc:	00 
  8021dd:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8021e3:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  8021e9:	48 89 d1             	mov    %rdx,%rcx
  8021ec:	48 89 c2             	mov    %rax,%rdx
  8021ef:	be 00 00 00 00       	mov    $0x0,%esi
  8021f4:	bf 12 00 00 00       	mov    $0x12,%edi
  8021f9:	48 b8 51 1c 80 00 00 	movabs $0x801c51,%rax
  802200:	00 00 00 
  802203:	ff d0                	callq  *%rax
  802205:	c9                   	leaveq 
  802206:	c3                   	retq   

0000000000802207 <fd2num>:
  802207:	55                   	push   %rbp
  802208:	48 89 e5             	mov    %rsp,%rbp
  80220b:	48 83 ec 08          	sub    $0x8,%rsp
  80220f:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802213:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  802217:	48 b8 00 00 00 30 ff 	movabs $0xffffffff30000000,%rax
  80221e:	ff ff ff 
  802221:	48 01 d0             	add    %rdx,%rax
  802224:	48 c1 e8 0c          	shr    $0xc,%rax
  802228:	c9                   	leaveq 
  802229:	c3                   	retq   

000000000080222a <fd2data>:
  80222a:	55                   	push   %rbp
  80222b:	48 89 e5             	mov    %rsp,%rbp
  80222e:	48 83 ec 08          	sub    $0x8,%rsp
  802232:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802236:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80223a:	48 89 c7             	mov    %rax,%rdi
  80223d:	48 b8 07 22 80 00 00 	movabs $0x802207,%rax
  802244:	00 00 00 
  802247:	ff d0                	callq  *%rax
  802249:	48 05 20 00 0d 00    	add    $0xd0020,%rax
  80224f:	48 c1 e0 0c          	shl    $0xc,%rax
  802253:	c9                   	leaveq 
  802254:	c3                   	retq   

0000000000802255 <fd_alloc>:
  802255:	55                   	push   %rbp
  802256:	48 89 e5             	mov    %rsp,%rbp
  802259:	48 83 ec 18          	sub    $0x18,%rsp
  80225d:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802261:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  802268:	eb 6b                	jmp    8022d5 <fd_alloc+0x80>
  80226a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80226d:	48 98                	cltq   
  80226f:	48 05 00 00 0d 00    	add    $0xd0000,%rax
  802275:	48 c1 e0 0c          	shl    $0xc,%rax
  802279:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  80227d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802281:	48 c1 e8 15          	shr    $0x15,%rax
  802285:	48 89 c2             	mov    %rax,%rdx
  802288:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  80228f:	01 00 00 
  802292:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802296:	83 e0 01             	and    $0x1,%eax
  802299:	48 85 c0             	test   %rax,%rax
  80229c:	74 21                	je     8022bf <fd_alloc+0x6a>
  80229e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8022a2:	48 c1 e8 0c          	shr    $0xc,%rax
  8022a6:	48 89 c2             	mov    %rax,%rdx
  8022a9:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  8022b0:	01 00 00 
  8022b3:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8022b7:	83 e0 01             	and    $0x1,%eax
  8022ba:	48 85 c0             	test   %rax,%rax
  8022bd:	75 12                	jne    8022d1 <fd_alloc+0x7c>
  8022bf:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8022c3:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8022c7:	48 89 10             	mov    %rdx,(%rax)
  8022ca:	b8 00 00 00 00       	mov    $0x0,%eax
  8022cf:	eb 1a                	jmp    8022eb <fd_alloc+0x96>
  8022d1:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8022d5:	83 7d fc 1f          	cmpl   $0x1f,-0x4(%rbp)
  8022d9:	7e 8f                	jle    80226a <fd_alloc+0x15>
  8022db:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8022df:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
  8022e6:	b8 f5 ff ff ff       	mov    $0xfffffff5,%eax
  8022eb:	c9                   	leaveq 
  8022ec:	c3                   	retq   

00000000008022ed <fd_lookup>:
  8022ed:	55                   	push   %rbp
  8022ee:	48 89 e5             	mov    %rsp,%rbp
  8022f1:	48 83 ec 20          	sub    $0x20,%rsp
  8022f5:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8022f8:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8022fc:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  802300:	78 06                	js     802308 <fd_lookup+0x1b>
  802302:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%rbp)
  802306:	7e 07                	jle    80230f <fd_lookup+0x22>
  802308:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  80230d:	eb 6c                	jmp    80237b <fd_lookup+0x8e>
  80230f:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802312:	48 98                	cltq   
  802314:	48 05 00 00 0d 00    	add    $0xd0000,%rax
  80231a:	48 c1 e0 0c          	shl    $0xc,%rax
  80231e:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  802322:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802326:	48 c1 e8 15          	shr    $0x15,%rax
  80232a:	48 89 c2             	mov    %rax,%rdx
  80232d:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  802334:	01 00 00 
  802337:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  80233b:	83 e0 01             	and    $0x1,%eax
  80233e:	48 85 c0             	test   %rax,%rax
  802341:	74 21                	je     802364 <fd_lookup+0x77>
  802343:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802347:	48 c1 e8 0c          	shr    $0xc,%rax
  80234b:	48 89 c2             	mov    %rax,%rdx
  80234e:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  802355:	01 00 00 
  802358:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  80235c:	83 e0 01             	and    $0x1,%eax
  80235f:	48 85 c0             	test   %rax,%rax
  802362:	75 07                	jne    80236b <fd_lookup+0x7e>
  802364:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  802369:	eb 10                	jmp    80237b <fd_lookup+0x8e>
  80236b:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80236f:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  802373:	48 89 10             	mov    %rdx,(%rax)
  802376:	b8 00 00 00 00       	mov    $0x0,%eax
  80237b:	c9                   	leaveq 
  80237c:	c3                   	retq   

000000000080237d <fd_close>:
  80237d:	55                   	push   %rbp
  80237e:	48 89 e5             	mov    %rsp,%rbp
  802381:	48 83 ec 30          	sub    $0x30,%rsp
  802385:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  802389:	89 f0                	mov    %esi,%eax
  80238b:	88 45 d4             	mov    %al,-0x2c(%rbp)
  80238e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  802392:	48 89 c7             	mov    %rax,%rdi
  802395:	48 b8 07 22 80 00 00 	movabs $0x802207,%rax
  80239c:	00 00 00 
  80239f:	ff d0                	callq  *%rax
  8023a1:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  8023a5:	48 89 d6             	mov    %rdx,%rsi
  8023a8:	89 c7                	mov    %eax,%edi
  8023aa:	48 b8 ed 22 80 00 00 	movabs $0x8022ed,%rax
  8023b1:	00 00 00 
  8023b4:	ff d0                	callq  *%rax
  8023b6:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8023b9:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8023bd:	78 0a                	js     8023c9 <fd_close+0x4c>
  8023bf:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8023c3:	48 39 45 d8          	cmp    %rax,-0x28(%rbp)
  8023c7:	74 12                	je     8023db <fd_close+0x5e>
  8023c9:	80 7d d4 00          	cmpb   $0x0,-0x2c(%rbp)
  8023cd:	74 05                	je     8023d4 <fd_close+0x57>
  8023cf:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8023d2:	eb 05                	jmp    8023d9 <fd_close+0x5c>
  8023d4:	b8 00 00 00 00       	mov    $0x0,%eax
  8023d9:	eb 69                	jmp    802444 <fd_close+0xc7>
  8023db:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8023df:	8b 00                	mov    (%rax),%eax
  8023e1:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  8023e5:	48 89 d6             	mov    %rdx,%rsi
  8023e8:	89 c7                	mov    %eax,%edi
  8023ea:	48 b8 46 24 80 00 00 	movabs $0x802446,%rax
  8023f1:	00 00 00 
  8023f4:	ff d0                	callq  *%rax
  8023f6:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8023f9:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8023fd:	78 2a                	js     802429 <fd_close+0xac>
  8023ff:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802403:	48 8b 40 20          	mov    0x20(%rax),%rax
  802407:	48 85 c0             	test   %rax,%rax
  80240a:	74 16                	je     802422 <fd_close+0xa5>
  80240c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802410:	48 8b 40 20          	mov    0x20(%rax),%rax
  802414:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  802418:	48 89 d7             	mov    %rdx,%rdi
  80241b:	ff d0                	callq  *%rax
  80241d:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802420:	eb 07                	jmp    802429 <fd_close+0xac>
  802422:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  802429:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80242d:	48 89 c6             	mov    %rax,%rsi
  802430:	bf 00 00 00 00       	mov    $0x0,%edi
  802435:	48 b8 d2 1e 80 00 00 	movabs $0x801ed2,%rax
  80243c:	00 00 00 
  80243f:	ff d0                	callq  *%rax
  802441:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802444:	c9                   	leaveq 
  802445:	c3                   	retq   

0000000000802446 <dev_lookup>:
  802446:	55                   	push   %rbp
  802447:	48 89 e5             	mov    %rsp,%rbp
  80244a:	48 83 ec 20          	sub    $0x20,%rsp
  80244e:	89 7d ec             	mov    %edi,-0x14(%rbp)
  802451:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802455:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  80245c:	eb 41                	jmp    80249f <dev_lookup+0x59>
  80245e:	48 b8 20 60 80 00 00 	movabs $0x806020,%rax
  802465:	00 00 00 
  802468:	8b 55 fc             	mov    -0x4(%rbp),%edx
  80246b:	48 63 d2             	movslq %edx,%rdx
  80246e:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802472:	8b 00                	mov    (%rax),%eax
  802474:	3b 45 ec             	cmp    -0x14(%rbp),%eax
  802477:	75 22                	jne    80249b <dev_lookup+0x55>
  802479:	48 b8 20 60 80 00 00 	movabs $0x806020,%rax
  802480:	00 00 00 
  802483:	8b 55 fc             	mov    -0x4(%rbp),%edx
  802486:	48 63 d2             	movslq %edx,%rdx
  802489:	48 8b 14 d0          	mov    (%rax,%rdx,8),%rdx
  80248d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802491:	48 89 10             	mov    %rdx,(%rax)
  802494:	b8 00 00 00 00       	mov    $0x0,%eax
  802499:	eb 60                	jmp    8024fb <dev_lookup+0xb5>
  80249b:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  80249f:	48 b8 20 60 80 00 00 	movabs $0x806020,%rax
  8024a6:	00 00 00 
  8024a9:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8024ac:	48 63 d2             	movslq %edx,%rdx
  8024af:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8024b3:	48 85 c0             	test   %rax,%rax
  8024b6:	75 a6                	jne    80245e <dev_lookup+0x18>
  8024b8:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  8024bf:	00 00 00 
  8024c2:	48 8b 00             	mov    (%rax),%rax
  8024c5:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  8024cb:	8b 55 ec             	mov    -0x14(%rbp),%edx
  8024ce:	89 c6                	mov    %eax,%esi
  8024d0:	48 bf 98 4c 80 00 00 	movabs $0x804c98,%rdi
  8024d7:	00 00 00 
  8024da:	b8 00 00 00 00       	mov    $0x0,%eax
  8024df:	48 b9 43 09 80 00 00 	movabs $0x800943,%rcx
  8024e6:	00 00 00 
  8024e9:	ff d1                	callq  *%rcx
  8024eb:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8024ef:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
  8024f6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  8024fb:	c9                   	leaveq 
  8024fc:	c3                   	retq   

00000000008024fd <close>:
  8024fd:	55                   	push   %rbp
  8024fe:	48 89 e5             	mov    %rsp,%rbp
  802501:	48 83 ec 20          	sub    $0x20,%rsp
  802505:	89 7d ec             	mov    %edi,-0x14(%rbp)
  802508:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  80250c:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80250f:	48 89 d6             	mov    %rdx,%rsi
  802512:	89 c7                	mov    %eax,%edi
  802514:	48 b8 ed 22 80 00 00 	movabs $0x8022ed,%rax
  80251b:	00 00 00 
  80251e:	ff d0                	callq  *%rax
  802520:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802523:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802527:	79 05                	jns    80252e <close+0x31>
  802529:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80252c:	eb 18                	jmp    802546 <close+0x49>
  80252e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802532:	be 01 00 00 00       	mov    $0x1,%esi
  802537:	48 89 c7             	mov    %rax,%rdi
  80253a:	48 b8 7d 23 80 00 00 	movabs $0x80237d,%rax
  802541:	00 00 00 
  802544:	ff d0                	callq  *%rax
  802546:	c9                   	leaveq 
  802547:	c3                   	retq   

0000000000802548 <close_all>:
  802548:	55                   	push   %rbp
  802549:	48 89 e5             	mov    %rsp,%rbp
  80254c:	48 83 ec 10          	sub    $0x10,%rsp
  802550:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  802557:	eb 15                	jmp    80256e <close_all+0x26>
  802559:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80255c:	89 c7                	mov    %eax,%edi
  80255e:	48 b8 fd 24 80 00 00 	movabs $0x8024fd,%rax
  802565:	00 00 00 
  802568:	ff d0                	callq  *%rax
  80256a:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  80256e:	83 7d fc 1f          	cmpl   $0x1f,-0x4(%rbp)
  802572:	7e e5                	jle    802559 <close_all+0x11>
  802574:	c9                   	leaveq 
  802575:	c3                   	retq   

0000000000802576 <dup>:
  802576:	55                   	push   %rbp
  802577:	48 89 e5             	mov    %rsp,%rbp
  80257a:	48 83 ec 40          	sub    $0x40,%rsp
  80257e:	89 7d cc             	mov    %edi,-0x34(%rbp)
  802581:	89 75 c8             	mov    %esi,-0x38(%rbp)
  802584:	48 8d 55 d8          	lea    -0x28(%rbp),%rdx
  802588:	8b 45 cc             	mov    -0x34(%rbp),%eax
  80258b:	48 89 d6             	mov    %rdx,%rsi
  80258e:	89 c7                	mov    %eax,%edi
  802590:	48 b8 ed 22 80 00 00 	movabs $0x8022ed,%rax
  802597:	00 00 00 
  80259a:	ff d0                	callq  *%rax
  80259c:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80259f:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8025a3:	79 08                	jns    8025ad <dup+0x37>
  8025a5:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8025a8:	e9 70 01 00 00       	jmpq   80271d <dup+0x1a7>
  8025ad:	8b 45 c8             	mov    -0x38(%rbp),%eax
  8025b0:	89 c7                	mov    %eax,%edi
  8025b2:	48 b8 fd 24 80 00 00 	movabs $0x8024fd,%rax
  8025b9:	00 00 00 
  8025bc:	ff d0                	callq  *%rax
  8025be:	8b 45 c8             	mov    -0x38(%rbp),%eax
  8025c1:	48 98                	cltq   
  8025c3:	48 05 00 00 0d 00    	add    $0xd0000,%rax
  8025c9:	48 c1 e0 0c          	shl    $0xc,%rax
  8025cd:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  8025d1:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8025d5:	48 89 c7             	mov    %rax,%rdi
  8025d8:	48 b8 2a 22 80 00 00 	movabs $0x80222a,%rax
  8025df:	00 00 00 
  8025e2:	ff d0                	callq  *%rax
  8025e4:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  8025e8:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8025ec:	48 89 c7             	mov    %rax,%rdi
  8025ef:	48 b8 2a 22 80 00 00 	movabs $0x80222a,%rax
  8025f6:	00 00 00 
  8025f9:	ff d0                	callq  *%rax
  8025fb:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  8025ff:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802603:	48 c1 e8 15          	shr    $0x15,%rax
  802607:	48 89 c2             	mov    %rax,%rdx
  80260a:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  802611:	01 00 00 
  802614:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802618:	83 e0 01             	and    $0x1,%eax
  80261b:	48 85 c0             	test   %rax,%rax
  80261e:	74 73                	je     802693 <dup+0x11d>
  802620:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802624:	48 c1 e8 0c          	shr    $0xc,%rax
  802628:	48 89 c2             	mov    %rax,%rdx
  80262b:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  802632:	01 00 00 
  802635:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802639:	83 e0 01             	and    $0x1,%eax
  80263c:	48 85 c0             	test   %rax,%rax
  80263f:	74 52                	je     802693 <dup+0x11d>
  802641:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802645:	48 c1 e8 0c          	shr    $0xc,%rax
  802649:	48 89 c2             	mov    %rax,%rdx
  80264c:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  802653:	01 00 00 
  802656:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  80265a:	25 07 0e 00 00       	and    $0xe07,%eax
  80265f:	89 c1                	mov    %eax,%ecx
  802661:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  802665:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802669:	41 89 c8             	mov    %ecx,%r8d
  80266c:	48 89 d1             	mov    %rdx,%rcx
  80266f:	ba 00 00 00 00       	mov    $0x0,%edx
  802674:	48 89 c6             	mov    %rax,%rsi
  802677:	bf 00 00 00 00       	mov    $0x0,%edi
  80267c:	48 b8 77 1e 80 00 00 	movabs $0x801e77,%rax
  802683:	00 00 00 
  802686:	ff d0                	callq  *%rax
  802688:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80268b:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80268f:	79 02                	jns    802693 <dup+0x11d>
  802691:	eb 57                	jmp    8026ea <dup+0x174>
  802693:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  802697:	48 c1 e8 0c          	shr    $0xc,%rax
  80269b:	48 89 c2             	mov    %rax,%rdx
  80269e:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  8026a5:	01 00 00 
  8026a8:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8026ac:	25 07 0e 00 00       	and    $0xe07,%eax
  8026b1:	89 c1                	mov    %eax,%ecx
  8026b3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8026b7:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8026bb:	41 89 c8             	mov    %ecx,%r8d
  8026be:	48 89 d1             	mov    %rdx,%rcx
  8026c1:	ba 00 00 00 00       	mov    $0x0,%edx
  8026c6:	48 89 c6             	mov    %rax,%rsi
  8026c9:	bf 00 00 00 00       	mov    $0x0,%edi
  8026ce:	48 b8 77 1e 80 00 00 	movabs $0x801e77,%rax
  8026d5:	00 00 00 
  8026d8:	ff d0                	callq  *%rax
  8026da:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8026dd:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8026e1:	79 02                	jns    8026e5 <dup+0x16f>
  8026e3:	eb 05                	jmp    8026ea <dup+0x174>
  8026e5:	8b 45 c8             	mov    -0x38(%rbp),%eax
  8026e8:	eb 33                	jmp    80271d <dup+0x1a7>
  8026ea:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8026ee:	48 89 c6             	mov    %rax,%rsi
  8026f1:	bf 00 00 00 00       	mov    $0x0,%edi
  8026f6:	48 b8 d2 1e 80 00 00 	movabs $0x801ed2,%rax
  8026fd:	00 00 00 
  802700:	ff d0                	callq  *%rax
  802702:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802706:	48 89 c6             	mov    %rax,%rsi
  802709:	bf 00 00 00 00       	mov    $0x0,%edi
  80270e:	48 b8 d2 1e 80 00 00 	movabs $0x801ed2,%rax
  802715:	00 00 00 
  802718:	ff d0                	callq  *%rax
  80271a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80271d:	c9                   	leaveq 
  80271e:	c3                   	retq   

000000000080271f <read>:
  80271f:	55                   	push   %rbp
  802720:	48 89 e5             	mov    %rsp,%rbp
  802723:	48 83 ec 40          	sub    $0x40,%rsp
  802727:	89 7d dc             	mov    %edi,-0x24(%rbp)
  80272a:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  80272e:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  802732:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  802736:	8b 45 dc             	mov    -0x24(%rbp),%eax
  802739:	48 89 d6             	mov    %rdx,%rsi
  80273c:	89 c7                	mov    %eax,%edi
  80273e:	48 b8 ed 22 80 00 00 	movabs $0x8022ed,%rax
  802745:	00 00 00 
  802748:	ff d0                	callq  *%rax
  80274a:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80274d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802751:	78 24                	js     802777 <read+0x58>
  802753:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802757:	8b 00                	mov    (%rax),%eax
  802759:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  80275d:	48 89 d6             	mov    %rdx,%rsi
  802760:	89 c7                	mov    %eax,%edi
  802762:	48 b8 46 24 80 00 00 	movabs $0x802446,%rax
  802769:	00 00 00 
  80276c:	ff d0                	callq  *%rax
  80276e:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802771:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802775:	79 05                	jns    80277c <read+0x5d>
  802777:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80277a:	eb 76                	jmp    8027f2 <read+0xd3>
  80277c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802780:	8b 40 08             	mov    0x8(%rax),%eax
  802783:	83 e0 03             	and    $0x3,%eax
  802786:	83 f8 01             	cmp    $0x1,%eax
  802789:	75 3a                	jne    8027c5 <read+0xa6>
  80278b:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  802792:	00 00 00 
  802795:	48 8b 00             	mov    (%rax),%rax
  802798:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  80279e:	8b 55 dc             	mov    -0x24(%rbp),%edx
  8027a1:	89 c6                	mov    %eax,%esi
  8027a3:	48 bf b7 4c 80 00 00 	movabs $0x804cb7,%rdi
  8027aa:	00 00 00 
  8027ad:	b8 00 00 00 00       	mov    $0x0,%eax
  8027b2:	48 b9 43 09 80 00 00 	movabs $0x800943,%rcx
  8027b9:	00 00 00 
  8027bc:	ff d1                	callq  *%rcx
  8027be:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  8027c3:	eb 2d                	jmp    8027f2 <read+0xd3>
  8027c5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8027c9:	48 8b 40 10          	mov    0x10(%rax),%rax
  8027cd:	48 85 c0             	test   %rax,%rax
  8027d0:	75 07                	jne    8027d9 <read+0xba>
  8027d2:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  8027d7:	eb 19                	jmp    8027f2 <read+0xd3>
  8027d9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8027dd:	48 8b 40 10          	mov    0x10(%rax),%rax
  8027e1:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8027e5:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8027e9:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  8027ed:	48 89 cf             	mov    %rcx,%rdi
  8027f0:	ff d0                	callq  *%rax
  8027f2:	c9                   	leaveq 
  8027f3:	c3                   	retq   

00000000008027f4 <readn>:
  8027f4:	55                   	push   %rbp
  8027f5:	48 89 e5             	mov    %rsp,%rbp
  8027f8:	48 83 ec 30          	sub    $0x30,%rsp
  8027fc:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8027ff:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802803:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  802807:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  80280e:	eb 49                	jmp    802859 <readn+0x65>
  802810:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802813:	48 98                	cltq   
  802815:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  802819:	48 29 c2             	sub    %rax,%rdx
  80281c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80281f:	48 63 c8             	movslq %eax,%rcx
  802822:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802826:	48 01 c1             	add    %rax,%rcx
  802829:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80282c:	48 89 ce             	mov    %rcx,%rsi
  80282f:	89 c7                	mov    %eax,%edi
  802831:	48 b8 1f 27 80 00 00 	movabs $0x80271f,%rax
  802838:	00 00 00 
  80283b:	ff d0                	callq  *%rax
  80283d:	89 45 f8             	mov    %eax,-0x8(%rbp)
  802840:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  802844:	79 05                	jns    80284b <readn+0x57>
  802846:	8b 45 f8             	mov    -0x8(%rbp),%eax
  802849:	eb 1c                	jmp    802867 <readn+0x73>
  80284b:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  80284f:	75 02                	jne    802853 <readn+0x5f>
  802851:	eb 11                	jmp    802864 <readn+0x70>
  802853:	8b 45 f8             	mov    -0x8(%rbp),%eax
  802856:	01 45 fc             	add    %eax,-0x4(%rbp)
  802859:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80285c:	48 98                	cltq   
  80285e:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  802862:	72 ac                	jb     802810 <readn+0x1c>
  802864:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802867:	c9                   	leaveq 
  802868:	c3                   	retq   

0000000000802869 <write>:
  802869:	55                   	push   %rbp
  80286a:	48 89 e5             	mov    %rsp,%rbp
  80286d:	48 83 ec 40          	sub    $0x40,%rsp
  802871:	89 7d dc             	mov    %edi,-0x24(%rbp)
  802874:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  802878:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  80287c:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  802880:	8b 45 dc             	mov    -0x24(%rbp),%eax
  802883:	48 89 d6             	mov    %rdx,%rsi
  802886:	89 c7                	mov    %eax,%edi
  802888:	48 b8 ed 22 80 00 00 	movabs $0x8022ed,%rax
  80288f:	00 00 00 
  802892:	ff d0                	callq  *%rax
  802894:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802897:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80289b:	78 24                	js     8028c1 <write+0x58>
  80289d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8028a1:	8b 00                	mov    (%rax),%eax
  8028a3:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  8028a7:	48 89 d6             	mov    %rdx,%rsi
  8028aa:	89 c7                	mov    %eax,%edi
  8028ac:	48 b8 46 24 80 00 00 	movabs $0x802446,%rax
  8028b3:	00 00 00 
  8028b6:	ff d0                	callq  *%rax
  8028b8:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8028bb:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8028bf:	79 05                	jns    8028c6 <write+0x5d>
  8028c1:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8028c4:	eb 75                	jmp    80293b <write+0xd2>
  8028c6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8028ca:	8b 40 08             	mov    0x8(%rax),%eax
  8028cd:	83 e0 03             	and    $0x3,%eax
  8028d0:	85 c0                	test   %eax,%eax
  8028d2:	75 3a                	jne    80290e <write+0xa5>
  8028d4:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  8028db:	00 00 00 
  8028de:	48 8b 00             	mov    (%rax),%rax
  8028e1:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  8028e7:	8b 55 dc             	mov    -0x24(%rbp),%edx
  8028ea:	89 c6                	mov    %eax,%esi
  8028ec:	48 bf d3 4c 80 00 00 	movabs $0x804cd3,%rdi
  8028f3:	00 00 00 
  8028f6:	b8 00 00 00 00       	mov    $0x0,%eax
  8028fb:	48 b9 43 09 80 00 00 	movabs $0x800943,%rcx
  802902:	00 00 00 
  802905:	ff d1                	callq  *%rcx
  802907:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  80290c:	eb 2d                	jmp    80293b <write+0xd2>
  80290e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802912:	48 8b 40 18          	mov    0x18(%rax),%rax
  802916:	48 85 c0             	test   %rax,%rax
  802919:	75 07                	jne    802922 <write+0xb9>
  80291b:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  802920:	eb 19                	jmp    80293b <write+0xd2>
  802922:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802926:	48 8b 40 18          	mov    0x18(%rax),%rax
  80292a:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  80292e:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  802932:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  802936:	48 89 cf             	mov    %rcx,%rdi
  802939:	ff d0                	callq  *%rax
  80293b:	c9                   	leaveq 
  80293c:	c3                   	retq   

000000000080293d <seek>:
  80293d:	55                   	push   %rbp
  80293e:	48 89 e5             	mov    %rsp,%rbp
  802941:	48 83 ec 18          	sub    $0x18,%rsp
  802945:	89 7d ec             	mov    %edi,-0x14(%rbp)
  802948:	89 75 e8             	mov    %esi,-0x18(%rbp)
  80294b:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  80294f:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802952:	48 89 d6             	mov    %rdx,%rsi
  802955:	89 c7                	mov    %eax,%edi
  802957:	48 b8 ed 22 80 00 00 	movabs $0x8022ed,%rax
  80295e:	00 00 00 
  802961:	ff d0                	callq  *%rax
  802963:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802966:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80296a:	79 05                	jns    802971 <seek+0x34>
  80296c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80296f:	eb 0f                	jmp    802980 <seek+0x43>
  802971:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802975:	8b 55 e8             	mov    -0x18(%rbp),%edx
  802978:	89 50 04             	mov    %edx,0x4(%rax)
  80297b:	b8 00 00 00 00       	mov    $0x0,%eax
  802980:	c9                   	leaveq 
  802981:	c3                   	retq   

0000000000802982 <ftruncate>:
  802982:	55                   	push   %rbp
  802983:	48 89 e5             	mov    %rsp,%rbp
  802986:	48 83 ec 30          	sub    $0x30,%rsp
  80298a:	89 7d dc             	mov    %edi,-0x24(%rbp)
  80298d:	89 75 d8             	mov    %esi,-0x28(%rbp)
  802990:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  802994:	8b 45 dc             	mov    -0x24(%rbp),%eax
  802997:	48 89 d6             	mov    %rdx,%rsi
  80299a:	89 c7                	mov    %eax,%edi
  80299c:	48 b8 ed 22 80 00 00 	movabs $0x8022ed,%rax
  8029a3:	00 00 00 
  8029a6:	ff d0                	callq  *%rax
  8029a8:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8029ab:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8029af:	78 24                	js     8029d5 <ftruncate+0x53>
  8029b1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8029b5:	8b 00                	mov    (%rax),%eax
  8029b7:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  8029bb:	48 89 d6             	mov    %rdx,%rsi
  8029be:	89 c7                	mov    %eax,%edi
  8029c0:	48 b8 46 24 80 00 00 	movabs $0x802446,%rax
  8029c7:	00 00 00 
  8029ca:	ff d0                	callq  *%rax
  8029cc:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8029cf:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8029d3:	79 05                	jns    8029da <ftruncate+0x58>
  8029d5:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8029d8:	eb 72                	jmp    802a4c <ftruncate+0xca>
  8029da:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8029de:	8b 40 08             	mov    0x8(%rax),%eax
  8029e1:	83 e0 03             	and    $0x3,%eax
  8029e4:	85 c0                	test   %eax,%eax
  8029e6:	75 3a                	jne    802a22 <ftruncate+0xa0>
  8029e8:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  8029ef:	00 00 00 
  8029f2:	48 8b 00             	mov    (%rax),%rax
  8029f5:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  8029fb:	8b 55 dc             	mov    -0x24(%rbp),%edx
  8029fe:	89 c6                	mov    %eax,%esi
  802a00:	48 bf f0 4c 80 00 00 	movabs $0x804cf0,%rdi
  802a07:	00 00 00 
  802a0a:	b8 00 00 00 00       	mov    $0x0,%eax
  802a0f:	48 b9 43 09 80 00 00 	movabs $0x800943,%rcx
  802a16:	00 00 00 
  802a19:	ff d1                	callq  *%rcx
  802a1b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  802a20:	eb 2a                	jmp    802a4c <ftruncate+0xca>
  802a22:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802a26:	48 8b 40 30          	mov    0x30(%rax),%rax
  802a2a:	48 85 c0             	test   %rax,%rax
  802a2d:	75 07                	jne    802a36 <ftruncate+0xb4>
  802a2f:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  802a34:	eb 16                	jmp    802a4c <ftruncate+0xca>
  802a36:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802a3a:	48 8b 40 30          	mov    0x30(%rax),%rax
  802a3e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  802a42:	8b 4d d8             	mov    -0x28(%rbp),%ecx
  802a45:	89 ce                	mov    %ecx,%esi
  802a47:	48 89 d7             	mov    %rdx,%rdi
  802a4a:	ff d0                	callq  *%rax
  802a4c:	c9                   	leaveq 
  802a4d:	c3                   	retq   

0000000000802a4e <fstat>:
  802a4e:	55                   	push   %rbp
  802a4f:	48 89 e5             	mov    %rsp,%rbp
  802a52:	48 83 ec 30          	sub    $0x30,%rsp
  802a56:	89 7d dc             	mov    %edi,-0x24(%rbp)
  802a59:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  802a5d:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  802a61:	8b 45 dc             	mov    -0x24(%rbp),%eax
  802a64:	48 89 d6             	mov    %rdx,%rsi
  802a67:	89 c7                	mov    %eax,%edi
  802a69:	48 b8 ed 22 80 00 00 	movabs $0x8022ed,%rax
  802a70:	00 00 00 
  802a73:	ff d0                	callq  *%rax
  802a75:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802a78:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802a7c:	78 24                	js     802aa2 <fstat+0x54>
  802a7e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802a82:	8b 00                	mov    (%rax),%eax
  802a84:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  802a88:	48 89 d6             	mov    %rdx,%rsi
  802a8b:	89 c7                	mov    %eax,%edi
  802a8d:	48 b8 46 24 80 00 00 	movabs $0x802446,%rax
  802a94:	00 00 00 
  802a97:	ff d0                	callq  *%rax
  802a99:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802a9c:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802aa0:	79 05                	jns    802aa7 <fstat+0x59>
  802aa2:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802aa5:	eb 5e                	jmp    802b05 <fstat+0xb7>
  802aa7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802aab:	48 8b 40 28          	mov    0x28(%rax),%rax
  802aaf:	48 85 c0             	test   %rax,%rax
  802ab2:	75 07                	jne    802abb <fstat+0x6d>
  802ab4:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  802ab9:	eb 4a                	jmp    802b05 <fstat+0xb7>
  802abb:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802abf:	c6 00 00             	movb   $0x0,(%rax)
  802ac2:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802ac6:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%rax)
  802acd:	00 00 00 
  802ad0:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802ad4:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%rax)
  802adb:	00 00 00 
  802ade:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  802ae2:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802ae6:	48 89 90 88 00 00 00 	mov    %rdx,0x88(%rax)
  802aed:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802af1:	48 8b 40 28          	mov    0x28(%rax),%rax
  802af5:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  802af9:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  802afd:	48 89 ce             	mov    %rcx,%rsi
  802b00:	48 89 d7             	mov    %rdx,%rdi
  802b03:	ff d0                	callq  *%rax
  802b05:	c9                   	leaveq 
  802b06:	c3                   	retq   

0000000000802b07 <stat>:
  802b07:	55                   	push   %rbp
  802b08:	48 89 e5             	mov    %rsp,%rbp
  802b0b:	48 83 ec 20          	sub    $0x20,%rsp
  802b0f:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802b13:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802b17:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802b1b:	be 00 00 00 00       	mov    $0x0,%esi
  802b20:	48 89 c7             	mov    %rax,%rdi
  802b23:	48 b8 f5 2b 80 00 00 	movabs $0x802bf5,%rax
  802b2a:	00 00 00 
  802b2d:	ff d0                	callq  *%rax
  802b2f:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802b32:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802b36:	79 05                	jns    802b3d <stat+0x36>
  802b38:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802b3b:	eb 2f                	jmp    802b6c <stat+0x65>
  802b3d:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  802b41:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802b44:	48 89 d6             	mov    %rdx,%rsi
  802b47:	89 c7                	mov    %eax,%edi
  802b49:	48 b8 4e 2a 80 00 00 	movabs $0x802a4e,%rax
  802b50:	00 00 00 
  802b53:	ff d0                	callq  *%rax
  802b55:	89 45 f8             	mov    %eax,-0x8(%rbp)
  802b58:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802b5b:	89 c7                	mov    %eax,%edi
  802b5d:	48 b8 fd 24 80 00 00 	movabs $0x8024fd,%rax
  802b64:	00 00 00 
  802b67:	ff d0                	callq  *%rax
  802b69:	8b 45 f8             	mov    -0x8(%rbp),%eax
  802b6c:	c9                   	leaveq 
  802b6d:	c3                   	retq   

0000000000802b6e <fsipc>:
  802b6e:	55                   	push   %rbp
  802b6f:	48 89 e5             	mov    %rsp,%rbp
  802b72:	48 83 ec 10          	sub    $0x10,%rsp
  802b76:	89 7d fc             	mov    %edi,-0x4(%rbp)
  802b79:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  802b7d:	48 b8 00 70 80 00 00 	movabs $0x807000,%rax
  802b84:	00 00 00 
  802b87:	8b 00                	mov    (%rax),%eax
  802b89:	85 c0                	test   %eax,%eax
  802b8b:	75 1d                	jne    802baa <fsipc+0x3c>
  802b8d:	bf 01 00 00 00       	mov    $0x1,%edi
  802b92:	48 b8 1b 45 80 00 00 	movabs $0x80451b,%rax
  802b99:	00 00 00 
  802b9c:	ff d0                	callq  *%rax
  802b9e:	48 ba 00 70 80 00 00 	movabs $0x807000,%rdx
  802ba5:	00 00 00 
  802ba8:	89 02                	mov    %eax,(%rdx)
  802baa:	48 b8 00 70 80 00 00 	movabs $0x807000,%rax
  802bb1:	00 00 00 
  802bb4:	8b 00                	mov    (%rax),%eax
  802bb6:	8b 75 fc             	mov    -0x4(%rbp),%esi
  802bb9:	b9 07 00 00 00       	mov    $0x7,%ecx
  802bbe:	48 ba 00 80 80 00 00 	movabs $0x808000,%rdx
  802bc5:	00 00 00 
  802bc8:	89 c7                	mov    %eax,%edi
  802bca:	48 b8 10 44 80 00 00 	movabs $0x804410,%rax
  802bd1:	00 00 00 
  802bd4:	ff d0                	callq  *%rax
  802bd6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802bda:	ba 00 00 00 00       	mov    $0x0,%edx
  802bdf:	48 89 c6             	mov    %rax,%rsi
  802be2:	bf 00 00 00 00       	mov    $0x0,%edi
  802be7:	48 b8 4f 43 80 00 00 	movabs $0x80434f,%rax
  802bee:	00 00 00 
  802bf1:	ff d0                	callq  *%rax
  802bf3:	c9                   	leaveq 
  802bf4:	c3                   	retq   

0000000000802bf5 <open>:
  802bf5:	55                   	push   %rbp
  802bf6:	48 89 e5             	mov    %rsp,%rbp
  802bf9:	48 83 ec 20          	sub    $0x20,%rsp
  802bfd:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802c01:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  802c04:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802c08:	48 89 c7             	mov    %rax,%rdi
  802c0b:	48 b8 8c 14 80 00 00 	movabs $0x80148c,%rax
  802c12:	00 00 00 
  802c15:	ff d0                	callq  *%rax
  802c17:	3d ff 03 00 00       	cmp    $0x3ff,%eax
  802c1c:	7e 0a                	jle    802c28 <open+0x33>
  802c1e:	b8 f3 ff ff ff       	mov    $0xfffffff3,%eax
  802c23:	e9 a5 00 00 00       	jmpq   802ccd <open+0xd8>
  802c28:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  802c2c:	48 89 c7             	mov    %rax,%rdi
  802c2f:	48 b8 55 22 80 00 00 	movabs $0x802255,%rax
  802c36:	00 00 00 
  802c39:	ff d0                	callq  *%rax
  802c3b:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802c3e:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802c42:	79 08                	jns    802c4c <open+0x57>
  802c44:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802c47:	e9 81 00 00 00       	jmpq   802ccd <open+0xd8>
  802c4c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802c50:	48 89 c6             	mov    %rax,%rsi
  802c53:	48 bf 00 80 80 00 00 	movabs $0x808000,%rdi
  802c5a:	00 00 00 
  802c5d:	48 b8 f8 14 80 00 00 	movabs $0x8014f8,%rax
  802c64:	00 00 00 
  802c67:	ff d0                	callq  *%rax
  802c69:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802c70:	00 00 00 
  802c73:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  802c76:	89 90 00 04 00 00    	mov    %edx,0x400(%rax)
  802c7c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802c80:	48 89 c6             	mov    %rax,%rsi
  802c83:	bf 01 00 00 00       	mov    $0x1,%edi
  802c88:	48 b8 6e 2b 80 00 00 	movabs $0x802b6e,%rax
  802c8f:	00 00 00 
  802c92:	ff d0                	callq  *%rax
  802c94:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802c97:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802c9b:	79 1d                	jns    802cba <open+0xc5>
  802c9d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802ca1:	be 00 00 00 00       	mov    $0x0,%esi
  802ca6:	48 89 c7             	mov    %rax,%rdi
  802ca9:	48 b8 7d 23 80 00 00 	movabs $0x80237d,%rax
  802cb0:	00 00 00 
  802cb3:	ff d0                	callq  *%rax
  802cb5:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802cb8:	eb 13                	jmp    802ccd <open+0xd8>
  802cba:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802cbe:	48 89 c7             	mov    %rax,%rdi
  802cc1:	48 b8 07 22 80 00 00 	movabs $0x802207,%rax
  802cc8:	00 00 00 
  802ccb:	ff d0                	callq  *%rax
  802ccd:	c9                   	leaveq 
  802cce:	c3                   	retq   

0000000000802ccf <devfile_flush>:
  802ccf:	55                   	push   %rbp
  802cd0:	48 89 e5             	mov    %rsp,%rbp
  802cd3:	48 83 ec 10          	sub    $0x10,%rsp
  802cd7:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802cdb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802cdf:	8b 50 0c             	mov    0xc(%rax),%edx
  802ce2:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802ce9:	00 00 00 
  802cec:	89 10                	mov    %edx,(%rax)
  802cee:	be 00 00 00 00       	mov    $0x0,%esi
  802cf3:	bf 06 00 00 00       	mov    $0x6,%edi
  802cf8:	48 b8 6e 2b 80 00 00 	movabs $0x802b6e,%rax
  802cff:	00 00 00 
  802d02:	ff d0                	callq  *%rax
  802d04:	c9                   	leaveq 
  802d05:	c3                   	retq   

0000000000802d06 <devfile_read>:
  802d06:	55                   	push   %rbp
  802d07:	48 89 e5             	mov    %rsp,%rbp
  802d0a:	48 83 ec 30          	sub    $0x30,%rsp
  802d0e:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802d12:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802d16:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  802d1a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802d1e:	8b 50 0c             	mov    0xc(%rax),%edx
  802d21:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802d28:	00 00 00 
  802d2b:	89 10                	mov    %edx,(%rax)
  802d2d:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802d34:	00 00 00 
  802d37:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  802d3b:	48 89 50 08          	mov    %rdx,0x8(%rax)
  802d3f:	be 00 00 00 00       	mov    $0x0,%esi
  802d44:	bf 03 00 00 00       	mov    $0x3,%edi
  802d49:	48 b8 6e 2b 80 00 00 	movabs $0x802b6e,%rax
  802d50:	00 00 00 
  802d53:	ff d0                	callq  *%rax
  802d55:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802d58:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802d5c:	79 08                	jns    802d66 <devfile_read+0x60>
  802d5e:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802d61:	e9 a4 00 00 00       	jmpq   802e0a <devfile_read+0x104>
  802d66:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802d69:	48 98                	cltq   
  802d6b:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  802d6f:	76 35                	jbe    802da6 <devfile_read+0xa0>
  802d71:	48 b9 16 4d 80 00 00 	movabs $0x804d16,%rcx
  802d78:	00 00 00 
  802d7b:	48 ba 1d 4d 80 00 00 	movabs $0x804d1d,%rdx
  802d82:	00 00 00 
  802d85:	be 89 00 00 00       	mov    $0x89,%esi
  802d8a:	48 bf 32 4d 80 00 00 	movabs $0x804d32,%rdi
  802d91:	00 00 00 
  802d94:	b8 00 00 00 00       	mov    $0x0,%eax
  802d99:	49 b8 0a 07 80 00 00 	movabs $0x80070a,%r8
  802da0:	00 00 00 
  802da3:	41 ff d0             	callq  *%r8
  802da6:	81 7d fc 00 10 00 00 	cmpl   $0x1000,-0x4(%rbp)
  802dad:	7e 35                	jle    802de4 <devfile_read+0xde>
  802daf:	48 b9 40 4d 80 00 00 	movabs $0x804d40,%rcx
  802db6:	00 00 00 
  802db9:	48 ba 1d 4d 80 00 00 	movabs $0x804d1d,%rdx
  802dc0:	00 00 00 
  802dc3:	be 8a 00 00 00       	mov    $0x8a,%esi
  802dc8:	48 bf 32 4d 80 00 00 	movabs $0x804d32,%rdi
  802dcf:	00 00 00 
  802dd2:	b8 00 00 00 00       	mov    $0x0,%eax
  802dd7:	49 b8 0a 07 80 00 00 	movabs $0x80070a,%r8
  802dde:	00 00 00 
  802de1:	41 ff d0             	callq  *%r8
  802de4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802de7:	48 63 d0             	movslq %eax,%rdx
  802dea:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802dee:	48 be 00 80 80 00 00 	movabs $0x808000,%rsi
  802df5:	00 00 00 
  802df8:	48 89 c7             	mov    %rax,%rdi
  802dfb:	48 b8 1c 18 80 00 00 	movabs $0x80181c,%rax
  802e02:	00 00 00 
  802e05:	ff d0                	callq  *%rax
  802e07:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802e0a:	c9                   	leaveq 
  802e0b:	c3                   	retq   

0000000000802e0c <devfile_write>:
  802e0c:	55                   	push   %rbp
  802e0d:	48 89 e5             	mov    %rsp,%rbp
  802e10:	48 83 ec 40          	sub    $0x40,%rsp
  802e14:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  802e18:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  802e1c:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  802e20:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  802e24:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  802e28:	48 c7 45 f0 f4 0f 00 	movq   $0xff4,-0x10(%rbp)
  802e2f:	00 
  802e30:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802e34:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  802e38:	48 0f 46 45 f8       	cmovbe -0x8(%rbp),%rax
  802e3d:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
  802e41:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  802e45:	8b 50 0c             	mov    0xc(%rax),%edx
  802e48:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802e4f:	00 00 00 
  802e52:	89 10                	mov    %edx,(%rax)
  802e54:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802e5b:	00 00 00 
  802e5e:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  802e62:	48 89 50 08          	mov    %rdx,0x8(%rax)
  802e66:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  802e6a:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802e6e:	48 89 c6             	mov    %rax,%rsi
  802e71:	48 bf 10 80 80 00 00 	movabs $0x808010,%rdi
  802e78:	00 00 00 
  802e7b:	48 b8 1c 18 80 00 00 	movabs $0x80181c,%rax
  802e82:	00 00 00 
  802e85:	ff d0                	callq  *%rax
  802e87:	be 00 00 00 00       	mov    $0x0,%esi
  802e8c:	bf 04 00 00 00       	mov    $0x4,%edi
  802e91:	48 b8 6e 2b 80 00 00 	movabs $0x802b6e,%rax
  802e98:	00 00 00 
  802e9b:	ff d0                	callq  *%rax
  802e9d:	89 45 ec             	mov    %eax,-0x14(%rbp)
  802ea0:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  802ea4:	79 05                	jns    802eab <devfile_write+0x9f>
  802ea6:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802ea9:	eb 43                	jmp    802eee <devfile_write+0xe2>
  802eab:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802eae:	48 98                	cltq   
  802eb0:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  802eb4:	76 35                	jbe    802eeb <devfile_write+0xdf>
  802eb6:	48 b9 16 4d 80 00 00 	movabs $0x804d16,%rcx
  802ebd:	00 00 00 
  802ec0:	48 ba 1d 4d 80 00 00 	movabs $0x804d1d,%rdx
  802ec7:	00 00 00 
  802eca:	be a8 00 00 00       	mov    $0xa8,%esi
  802ecf:	48 bf 32 4d 80 00 00 	movabs $0x804d32,%rdi
  802ed6:	00 00 00 
  802ed9:	b8 00 00 00 00       	mov    $0x0,%eax
  802ede:	49 b8 0a 07 80 00 00 	movabs $0x80070a,%r8
  802ee5:	00 00 00 
  802ee8:	41 ff d0             	callq  *%r8
  802eeb:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802eee:	c9                   	leaveq 
  802eef:	c3                   	retq   

0000000000802ef0 <devfile_stat>:
  802ef0:	55                   	push   %rbp
  802ef1:	48 89 e5             	mov    %rsp,%rbp
  802ef4:	48 83 ec 20          	sub    $0x20,%rsp
  802ef8:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802efc:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802f00:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802f04:	8b 50 0c             	mov    0xc(%rax),%edx
  802f07:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802f0e:	00 00 00 
  802f11:	89 10                	mov    %edx,(%rax)
  802f13:	be 00 00 00 00       	mov    $0x0,%esi
  802f18:	bf 05 00 00 00       	mov    $0x5,%edi
  802f1d:	48 b8 6e 2b 80 00 00 	movabs $0x802b6e,%rax
  802f24:	00 00 00 
  802f27:	ff d0                	callq  *%rax
  802f29:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802f2c:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802f30:	79 05                	jns    802f37 <devfile_stat+0x47>
  802f32:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802f35:	eb 56                	jmp    802f8d <devfile_stat+0x9d>
  802f37:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802f3b:	48 be 00 80 80 00 00 	movabs $0x808000,%rsi
  802f42:	00 00 00 
  802f45:	48 89 c7             	mov    %rax,%rdi
  802f48:	48 b8 f8 14 80 00 00 	movabs $0x8014f8,%rax
  802f4f:	00 00 00 
  802f52:	ff d0                	callq  *%rax
  802f54:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802f5b:	00 00 00 
  802f5e:	8b 90 80 00 00 00    	mov    0x80(%rax),%edx
  802f64:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802f68:	89 90 80 00 00 00    	mov    %edx,0x80(%rax)
  802f6e:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802f75:	00 00 00 
  802f78:	8b 90 84 00 00 00    	mov    0x84(%rax),%edx
  802f7e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802f82:	89 90 84 00 00 00    	mov    %edx,0x84(%rax)
  802f88:	b8 00 00 00 00       	mov    $0x0,%eax
  802f8d:	c9                   	leaveq 
  802f8e:	c3                   	retq   

0000000000802f8f <devfile_trunc>:
  802f8f:	55                   	push   %rbp
  802f90:	48 89 e5             	mov    %rsp,%rbp
  802f93:	48 83 ec 10          	sub    $0x10,%rsp
  802f97:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802f9b:	89 75 f4             	mov    %esi,-0xc(%rbp)
  802f9e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802fa2:	8b 50 0c             	mov    0xc(%rax),%edx
  802fa5:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802fac:	00 00 00 
  802faf:	89 10                	mov    %edx,(%rax)
  802fb1:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802fb8:	00 00 00 
  802fbb:	8b 55 f4             	mov    -0xc(%rbp),%edx
  802fbe:	89 50 04             	mov    %edx,0x4(%rax)
  802fc1:	be 00 00 00 00       	mov    $0x0,%esi
  802fc6:	bf 02 00 00 00       	mov    $0x2,%edi
  802fcb:	48 b8 6e 2b 80 00 00 	movabs $0x802b6e,%rax
  802fd2:	00 00 00 
  802fd5:	ff d0                	callq  *%rax
  802fd7:	c9                   	leaveq 
  802fd8:	c3                   	retq   

0000000000802fd9 <remove>:
  802fd9:	55                   	push   %rbp
  802fda:	48 89 e5             	mov    %rsp,%rbp
  802fdd:	48 83 ec 10          	sub    $0x10,%rsp
  802fe1:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802fe5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802fe9:	48 89 c7             	mov    %rax,%rdi
  802fec:	48 b8 8c 14 80 00 00 	movabs $0x80148c,%rax
  802ff3:	00 00 00 
  802ff6:	ff d0                	callq  *%rax
  802ff8:	3d ff 03 00 00       	cmp    $0x3ff,%eax
  802ffd:	7e 07                	jle    803006 <remove+0x2d>
  802fff:	b8 f3 ff ff ff       	mov    $0xfffffff3,%eax
  803004:	eb 33                	jmp    803039 <remove+0x60>
  803006:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80300a:	48 89 c6             	mov    %rax,%rsi
  80300d:	48 bf 00 80 80 00 00 	movabs $0x808000,%rdi
  803014:	00 00 00 
  803017:	48 b8 f8 14 80 00 00 	movabs $0x8014f8,%rax
  80301e:	00 00 00 
  803021:	ff d0                	callq  *%rax
  803023:	be 00 00 00 00       	mov    $0x0,%esi
  803028:	bf 07 00 00 00       	mov    $0x7,%edi
  80302d:	48 b8 6e 2b 80 00 00 	movabs $0x802b6e,%rax
  803034:	00 00 00 
  803037:	ff d0                	callq  *%rax
  803039:	c9                   	leaveq 
  80303a:	c3                   	retq   

000000000080303b <sync>:
  80303b:	55                   	push   %rbp
  80303c:	48 89 e5             	mov    %rsp,%rbp
  80303f:	be 00 00 00 00       	mov    $0x0,%esi
  803044:	bf 08 00 00 00       	mov    $0x8,%edi
  803049:	48 b8 6e 2b 80 00 00 	movabs $0x802b6e,%rax
  803050:	00 00 00 
  803053:	ff d0                	callq  *%rax
  803055:	5d                   	pop    %rbp
  803056:	c3                   	retq   

0000000000803057 <copy>:
  803057:	55                   	push   %rbp
  803058:	48 89 e5             	mov    %rsp,%rbp
  80305b:	48 81 ec 20 02 00 00 	sub    $0x220,%rsp
  803062:	48 89 bd e8 fd ff ff 	mov    %rdi,-0x218(%rbp)
  803069:	48 89 b5 e0 fd ff ff 	mov    %rsi,-0x220(%rbp)
  803070:	48 8b 85 e8 fd ff ff 	mov    -0x218(%rbp),%rax
  803077:	be 00 00 00 00       	mov    $0x0,%esi
  80307c:	48 89 c7             	mov    %rax,%rdi
  80307f:	48 b8 f5 2b 80 00 00 	movabs $0x802bf5,%rax
  803086:	00 00 00 
  803089:	ff d0                	callq  *%rax
  80308b:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80308e:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803092:	79 28                	jns    8030bc <copy+0x65>
  803094:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803097:	89 c6                	mov    %eax,%esi
  803099:	48 bf 4c 4d 80 00 00 	movabs $0x804d4c,%rdi
  8030a0:	00 00 00 
  8030a3:	b8 00 00 00 00       	mov    $0x0,%eax
  8030a8:	48 ba 43 09 80 00 00 	movabs $0x800943,%rdx
  8030af:	00 00 00 
  8030b2:	ff d2                	callq  *%rdx
  8030b4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8030b7:	e9 74 01 00 00       	jmpq   803230 <copy+0x1d9>
  8030bc:	48 8b 85 e0 fd ff ff 	mov    -0x220(%rbp),%rax
  8030c3:	be 01 01 00 00       	mov    $0x101,%esi
  8030c8:	48 89 c7             	mov    %rax,%rdi
  8030cb:	48 b8 f5 2b 80 00 00 	movabs $0x802bf5,%rax
  8030d2:	00 00 00 
  8030d5:	ff d0                	callq  *%rax
  8030d7:	89 45 f8             	mov    %eax,-0x8(%rbp)
  8030da:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8030de:	79 39                	jns    803119 <copy+0xc2>
  8030e0:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8030e3:	89 c6                	mov    %eax,%esi
  8030e5:	48 bf 62 4d 80 00 00 	movabs $0x804d62,%rdi
  8030ec:	00 00 00 
  8030ef:	b8 00 00 00 00       	mov    $0x0,%eax
  8030f4:	48 ba 43 09 80 00 00 	movabs $0x800943,%rdx
  8030fb:	00 00 00 
  8030fe:	ff d2                	callq  *%rdx
  803100:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803103:	89 c7                	mov    %eax,%edi
  803105:	48 b8 fd 24 80 00 00 	movabs $0x8024fd,%rax
  80310c:	00 00 00 
  80310f:	ff d0                	callq  *%rax
  803111:	8b 45 f8             	mov    -0x8(%rbp),%eax
  803114:	e9 17 01 00 00       	jmpq   803230 <copy+0x1d9>
  803119:	eb 74                	jmp    80318f <copy+0x138>
  80311b:	8b 45 f4             	mov    -0xc(%rbp),%eax
  80311e:	48 63 d0             	movslq %eax,%rdx
  803121:	48 8d 8d f0 fd ff ff 	lea    -0x210(%rbp),%rcx
  803128:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80312b:	48 89 ce             	mov    %rcx,%rsi
  80312e:	89 c7                	mov    %eax,%edi
  803130:	48 b8 69 28 80 00 00 	movabs $0x802869,%rax
  803137:	00 00 00 
  80313a:	ff d0                	callq  *%rax
  80313c:	89 45 f0             	mov    %eax,-0x10(%rbp)
  80313f:	83 7d f0 00          	cmpl   $0x0,-0x10(%rbp)
  803143:	79 4a                	jns    80318f <copy+0x138>
  803145:	8b 45 f0             	mov    -0x10(%rbp),%eax
  803148:	89 c6                	mov    %eax,%esi
  80314a:	48 bf 7c 4d 80 00 00 	movabs $0x804d7c,%rdi
  803151:	00 00 00 
  803154:	b8 00 00 00 00       	mov    $0x0,%eax
  803159:	48 ba 43 09 80 00 00 	movabs $0x800943,%rdx
  803160:	00 00 00 
  803163:	ff d2                	callq  *%rdx
  803165:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803168:	89 c7                	mov    %eax,%edi
  80316a:	48 b8 fd 24 80 00 00 	movabs $0x8024fd,%rax
  803171:	00 00 00 
  803174:	ff d0                	callq  *%rax
  803176:	8b 45 f8             	mov    -0x8(%rbp),%eax
  803179:	89 c7                	mov    %eax,%edi
  80317b:	48 b8 fd 24 80 00 00 	movabs $0x8024fd,%rax
  803182:	00 00 00 
  803185:	ff d0                	callq  *%rax
  803187:	8b 45 f0             	mov    -0x10(%rbp),%eax
  80318a:	e9 a1 00 00 00       	jmpq   803230 <copy+0x1d9>
  80318f:	48 8d 8d f0 fd ff ff 	lea    -0x210(%rbp),%rcx
  803196:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803199:	ba 00 02 00 00       	mov    $0x200,%edx
  80319e:	48 89 ce             	mov    %rcx,%rsi
  8031a1:	89 c7                	mov    %eax,%edi
  8031a3:	48 b8 1f 27 80 00 00 	movabs $0x80271f,%rax
  8031aa:	00 00 00 
  8031ad:	ff d0                	callq  *%rax
  8031af:	89 45 f4             	mov    %eax,-0xc(%rbp)
  8031b2:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  8031b6:	0f 8f 5f ff ff ff    	jg     80311b <copy+0xc4>
  8031bc:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  8031c0:	79 47                	jns    803209 <copy+0x1b2>
  8031c2:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8031c5:	89 c6                	mov    %eax,%esi
  8031c7:	48 bf 8f 4d 80 00 00 	movabs $0x804d8f,%rdi
  8031ce:	00 00 00 
  8031d1:	b8 00 00 00 00       	mov    $0x0,%eax
  8031d6:	48 ba 43 09 80 00 00 	movabs $0x800943,%rdx
  8031dd:	00 00 00 
  8031e0:	ff d2                	callq  *%rdx
  8031e2:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8031e5:	89 c7                	mov    %eax,%edi
  8031e7:	48 b8 fd 24 80 00 00 	movabs $0x8024fd,%rax
  8031ee:	00 00 00 
  8031f1:	ff d0                	callq  *%rax
  8031f3:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8031f6:	89 c7                	mov    %eax,%edi
  8031f8:	48 b8 fd 24 80 00 00 	movabs $0x8024fd,%rax
  8031ff:	00 00 00 
  803202:	ff d0                	callq  *%rax
  803204:	8b 45 f4             	mov    -0xc(%rbp),%eax
  803207:	eb 27                	jmp    803230 <copy+0x1d9>
  803209:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80320c:	89 c7                	mov    %eax,%edi
  80320e:	48 b8 fd 24 80 00 00 	movabs $0x8024fd,%rax
  803215:	00 00 00 
  803218:	ff d0                	callq  *%rax
  80321a:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80321d:	89 c7                	mov    %eax,%edi
  80321f:	48 b8 fd 24 80 00 00 	movabs $0x8024fd,%rax
  803226:	00 00 00 
  803229:	ff d0                	callq  *%rax
  80322b:	b8 00 00 00 00       	mov    $0x0,%eax
  803230:	c9                   	leaveq 
  803231:	c3                   	retq   

0000000000803232 <fd2sockid>:
  803232:	55                   	push   %rbp
  803233:	48 89 e5             	mov    %rsp,%rbp
  803236:	48 83 ec 20          	sub    $0x20,%rsp
  80323a:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80323d:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  803241:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803244:	48 89 d6             	mov    %rdx,%rsi
  803247:	89 c7                	mov    %eax,%edi
  803249:	48 b8 ed 22 80 00 00 	movabs $0x8022ed,%rax
  803250:	00 00 00 
  803253:	ff d0                	callq  *%rax
  803255:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803258:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80325c:	79 05                	jns    803263 <fd2sockid+0x31>
  80325e:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803261:	eb 24                	jmp    803287 <fd2sockid+0x55>
  803263:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803267:	8b 10                	mov    (%rax),%edx
  803269:	48 b8 a0 60 80 00 00 	movabs $0x8060a0,%rax
  803270:	00 00 00 
  803273:	8b 00                	mov    (%rax),%eax
  803275:	39 c2                	cmp    %eax,%edx
  803277:	74 07                	je     803280 <fd2sockid+0x4e>
  803279:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  80327e:	eb 07                	jmp    803287 <fd2sockid+0x55>
  803280:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803284:	8b 40 0c             	mov    0xc(%rax),%eax
  803287:	c9                   	leaveq 
  803288:	c3                   	retq   

0000000000803289 <alloc_sockfd>:
  803289:	55                   	push   %rbp
  80328a:	48 89 e5             	mov    %rsp,%rbp
  80328d:	48 83 ec 20          	sub    $0x20,%rsp
  803291:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803294:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  803298:	48 89 c7             	mov    %rax,%rdi
  80329b:	48 b8 55 22 80 00 00 	movabs $0x802255,%rax
  8032a2:	00 00 00 
  8032a5:	ff d0                	callq  *%rax
  8032a7:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8032aa:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8032ae:	78 26                	js     8032d6 <alloc_sockfd+0x4d>
  8032b0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8032b4:	ba 07 04 00 00       	mov    $0x407,%edx
  8032b9:	48 89 c6             	mov    %rax,%rsi
  8032bc:	bf 00 00 00 00       	mov    $0x0,%edi
  8032c1:	48 b8 27 1e 80 00 00 	movabs $0x801e27,%rax
  8032c8:	00 00 00 
  8032cb:	ff d0                	callq  *%rax
  8032cd:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8032d0:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8032d4:	79 16                	jns    8032ec <alloc_sockfd+0x63>
  8032d6:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8032d9:	89 c7                	mov    %eax,%edi
  8032db:	48 b8 96 37 80 00 00 	movabs $0x803796,%rax
  8032e2:	00 00 00 
  8032e5:	ff d0                	callq  *%rax
  8032e7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8032ea:	eb 3a                	jmp    803326 <alloc_sockfd+0x9d>
  8032ec:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8032f0:	48 ba a0 60 80 00 00 	movabs $0x8060a0,%rdx
  8032f7:	00 00 00 
  8032fa:	8b 12                	mov    (%rdx),%edx
  8032fc:	89 10                	mov    %edx,(%rax)
  8032fe:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803302:	c7 40 08 02 00 00 00 	movl   $0x2,0x8(%rax)
  803309:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80330d:	8b 55 ec             	mov    -0x14(%rbp),%edx
  803310:	89 50 0c             	mov    %edx,0xc(%rax)
  803313:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803317:	48 89 c7             	mov    %rax,%rdi
  80331a:	48 b8 07 22 80 00 00 	movabs $0x802207,%rax
  803321:	00 00 00 
  803324:	ff d0                	callq  *%rax
  803326:	c9                   	leaveq 
  803327:	c3                   	retq   

0000000000803328 <accept>:
  803328:	55                   	push   %rbp
  803329:	48 89 e5             	mov    %rsp,%rbp
  80332c:	48 83 ec 30          	sub    $0x30,%rsp
  803330:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803333:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  803337:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80333b:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80333e:	89 c7                	mov    %eax,%edi
  803340:	48 b8 32 32 80 00 00 	movabs $0x803232,%rax
  803347:	00 00 00 
  80334a:	ff d0                	callq  *%rax
  80334c:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80334f:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803353:	79 05                	jns    80335a <accept+0x32>
  803355:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803358:	eb 3b                	jmp    803395 <accept+0x6d>
  80335a:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  80335e:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  803362:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803365:	48 89 ce             	mov    %rcx,%rsi
  803368:	89 c7                	mov    %eax,%edi
  80336a:	48 b8 73 36 80 00 00 	movabs $0x803673,%rax
  803371:	00 00 00 
  803374:	ff d0                	callq  *%rax
  803376:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803379:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80337d:	79 05                	jns    803384 <accept+0x5c>
  80337f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803382:	eb 11                	jmp    803395 <accept+0x6d>
  803384:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803387:	89 c7                	mov    %eax,%edi
  803389:	48 b8 89 32 80 00 00 	movabs $0x803289,%rax
  803390:	00 00 00 
  803393:	ff d0                	callq  *%rax
  803395:	c9                   	leaveq 
  803396:	c3                   	retq   

0000000000803397 <bind>:
  803397:	55                   	push   %rbp
  803398:	48 89 e5             	mov    %rsp,%rbp
  80339b:	48 83 ec 20          	sub    $0x20,%rsp
  80339f:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8033a2:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8033a6:	89 55 e8             	mov    %edx,-0x18(%rbp)
  8033a9:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8033ac:	89 c7                	mov    %eax,%edi
  8033ae:	48 b8 32 32 80 00 00 	movabs $0x803232,%rax
  8033b5:	00 00 00 
  8033b8:	ff d0                	callq  *%rax
  8033ba:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8033bd:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8033c1:	79 05                	jns    8033c8 <bind+0x31>
  8033c3:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8033c6:	eb 1b                	jmp    8033e3 <bind+0x4c>
  8033c8:	8b 55 e8             	mov    -0x18(%rbp),%edx
  8033cb:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  8033cf:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8033d2:	48 89 ce             	mov    %rcx,%rsi
  8033d5:	89 c7                	mov    %eax,%edi
  8033d7:	48 b8 f2 36 80 00 00 	movabs $0x8036f2,%rax
  8033de:	00 00 00 
  8033e1:	ff d0                	callq  *%rax
  8033e3:	c9                   	leaveq 
  8033e4:	c3                   	retq   

00000000008033e5 <shutdown>:
  8033e5:	55                   	push   %rbp
  8033e6:	48 89 e5             	mov    %rsp,%rbp
  8033e9:	48 83 ec 20          	sub    $0x20,%rsp
  8033ed:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8033f0:	89 75 e8             	mov    %esi,-0x18(%rbp)
  8033f3:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8033f6:	89 c7                	mov    %eax,%edi
  8033f8:	48 b8 32 32 80 00 00 	movabs $0x803232,%rax
  8033ff:	00 00 00 
  803402:	ff d0                	callq  *%rax
  803404:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803407:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80340b:	79 05                	jns    803412 <shutdown+0x2d>
  80340d:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803410:	eb 16                	jmp    803428 <shutdown+0x43>
  803412:	8b 55 e8             	mov    -0x18(%rbp),%edx
  803415:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803418:	89 d6                	mov    %edx,%esi
  80341a:	89 c7                	mov    %eax,%edi
  80341c:	48 b8 56 37 80 00 00 	movabs $0x803756,%rax
  803423:	00 00 00 
  803426:	ff d0                	callq  *%rax
  803428:	c9                   	leaveq 
  803429:	c3                   	retq   

000000000080342a <devsock_close>:
  80342a:	55                   	push   %rbp
  80342b:	48 89 e5             	mov    %rsp,%rbp
  80342e:	48 83 ec 10          	sub    $0x10,%rsp
  803432:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  803436:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80343a:	48 89 c7             	mov    %rax,%rdi
  80343d:	48 b8 8d 45 80 00 00 	movabs $0x80458d,%rax
  803444:	00 00 00 
  803447:	ff d0                	callq  *%rax
  803449:	83 f8 01             	cmp    $0x1,%eax
  80344c:	75 17                	jne    803465 <devsock_close+0x3b>
  80344e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803452:	8b 40 0c             	mov    0xc(%rax),%eax
  803455:	89 c7                	mov    %eax,%edi
  803457:	48 b8 96 37 80 00 00 	movabs $0x803796,%rax
  80345e:	00 00 00 
  803461:	ff d0                	callq  *%rax
  803463:	eb 05                	jmp    80346a <devsock_close+0x40>
  803465:	b8 00 00 00 00       	mov    $0x0,%eax
  80346a:	c9                   	leaveq 
  80346b:	c3                   	retq   

000000000080346c <connect>:
  80346c:	55                   	push   %rbp
  80346d:	48 89 e5             	mov    %rsp,%rbp
  803470:	48 83 ec 20          	sub    $0x20,%rsp
  803474:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803477:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80347b:	89 55 e8             	mov    %edx,-0x18(%rbp)
  80347e:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803481:	89 c7                	mov    %eax,%edi
  803483:	48 b8 32 32 80 00 00 	movabs $0x803232,%rax
  80348a:	00 00 00 
  80348d:	ff d0                	callq  *%rax
  80348f:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803492:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803496:	79 05                	jns    80349d <connect+0x31>
  803498:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80349b:	eb 1b                	jmp    8034b8 <connect+0x4c>
  80349d:	8b 55 e8             	mov    -0x18(%rbp),%edx
  8034a0:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  8034a4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8034a7:	48 89 ce             	mov    %rcx,%rsi
  8034aa:	89 c7                	mov    %eax,%edi
  8034ac:	48 b8 c3 37 80 00 00 	movabs $0x8037c3,%rax
  8034b3:	00 00 00 
  8034b6:	ff d0                	callq  *%rax
  8034b8:	c9                   	leaveq 
  8034b9:	c3                   	retq   

00000000008034ba <listen>:
  8034ba:	55                   	push   %rbp
  8034bb:	48 89 e5             	mov    %rsp,%rbp
  8034be:	48 83 ec 20          	sub    $0x20,%rsp
  8034c2:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8034c5:	89 75 e8             	mov    %esi,-0x18(%rbp)
  8034c8:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8034cb:	89 c7                	mov    %eax,%edi
  8034cd:	48 b8 32 32 80 00 00 	movabs $0x803232,%rax
  8034d4:	00 00 00 
  8034d7:	ff d0                	callq  *%rax
  8034d9:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8034dc:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8034e0:	79 05                	jns    8034e7 <listen+0x2d>
  8034e2:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8034e5:	eb 16                	jmp    8034fd <listen+0x43>
  8034e7:	8b 55 e8             	mov    -0x18(%rbp),%edx
  8034ea:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8034ed:	89 d6                	mov    %edx,%esi
  8034ef:	89 c7                	mov    %eax,%edi
  8034f1:	48 b8 27 38 80 00 00 	movabs $0x803827,%rax
  8034f8:	00 00 00 
  8034fb:	ff d0                	callq  *%rax
  8034fd:	c9                   	leaveq 
  8034fe:	c3                   	retq   

00000000008034ff <devsock_read>:
  8034ff:	55                   	push   %rbp
  803500:	48 89 e5             	mov    %rsp,%rbp
  803503:	48 83 ec 20          	sub    $0x20,%rsp
  803507:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80350b:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  80350f:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  803513:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  803517:	89 c2                	mov    %eax,%edx
  803519:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80351d:	8b 40 0c             	mov    0xc(%rax),%eax
  803520:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
  803524:	b9 00 00 00 00       	mov    $0x0,%ecx
  803529:	89 c7                	mov    %eax,%edi
  80352b:	48 b8 67 38 80 00 00 	movabs $0x803867,%rax
  803532:	00 00 00 
  803535:	ff d0                	callq  *%rax
  803537:	c9                   	leaveq 
  803538:	c3                   	retq   

0000000000803539 <devsock_write>:
  803539:	55                   	push   %rbp
  80353a:	48 89 e5             	mov    %rsp,%rbp
  80353d:	48 83 ec 20          	sub    $0x20,%rsp
  803541:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  803545:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  803549:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  80354d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  803551:	89 c2                	mov    %eax,%edx
  803553:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803557:	8b 40 0c             	mov    0xc(%rax),%eax
  80355a:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
  80355e:	b9 00 00 00 00       	mov    $0x0,%ecx
  803563:	89 c7                	mov    %eax,%edi
  803565:	48 b8 33 39 80 00 00 	movabs $0x803933,%rax
  80356c:	00 00 00 
  80356f:	ff d0                	callq  *%rax
  803571:	c9                   	leaveq 
  803572:	c3                   	retq   

0000000000803573 <devsock_stat>:
  803573:	55                   	push   %rbp
  803574:	48 89 e5             	mov    %rsp,%rbp
  803577:	48 83 ec 10          	sub    $0x10,%rsp
  80357b:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80357f:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  803583:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803587:	48 be aa 4d 80 00 00 	movabs $0x804daa,%rsi
  80358e:	00 00 00 
  803591:	48 89 c7             	mov    %rax,%rdi
  803594:	48 b8 f8 14 80 00 00 	movabs $0x8014f8,%rax
  80359b:	00 00 00 
  80359e:	ff d0                	callq  *%rax
  8035a0:	b8 00 00 00 00       	mov    $0x0,%eax
  8035a5:	c9                   	leaveq 
  8035a6:	c3                   	retq   

00000000008035a7 <socket>:
  8035a7:	55                   	push   %rbp
  8035a8:	48 89 e5             	mov    %rsp,%rbp
  8035ab:	48 83 ec 20          	sub    $0x20,%rsp
  8035af:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8035b2:	89 75 e8             	mov    %esi,-0x18(%rbp)
  8035b5:	89 55 e4             	mov    %edx,-0x1c(%rbp)
  8035b8:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  8035bb:	8b 4d e8             	mov    -0x18(%rbp),%ecx
  8035be:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8035c1:	89 ce                	mov    %ecx,%esi
  8035c3:	89 c7                	mov    %eax,%edi
  8035c5:	48 b8 eb 39 80 00 00 	movabs $0x8039eb,%rax
  8035cc:	00 00 00 
  8035cf:	ff d0                	callq  *%rax
  8035d1:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8035d4:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8035d8:	79 05                	jns    8035df <socket+0x38>
  8035da:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8035dd:	eb 11                	jmp    8035f0 <socket+0x49>
  8035df:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8035e2:	89 c7                	mov    %eax,%edi
  8035e4:	48 b8 89 32 80 00 00 	movabs $0x803289,%rax
  8035eb:	00 00 00 
  8035ee:	ff d0                	callq  *%rax
  8035f0:	c9                   	leaveq 
  8035f1:	c3                   	retq   

00000000008035f2 <nsipc>:
  8035f2:	55                   	push   %rbp
  8035f3:	48 89 e5             	mov    %rsp,%rbp
  8035f6:	48 83 ec 10          	sub    $0x10,%rsp
  8035fa:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8035fd:	48 b8 04 70 80 00 00 	movabs $0x807004,%rax
  803604:	00 00 00 
  803607:	8b 00                	mov    (%rax),%eax
  803609:	85 c0                	test   %eax,%eax
  80360b:	75 1d                	jne    80362a <nsipc+0x38>
  80360d:	bf 02 00 00 00       	mov    $0x2,%edi
  803612:	48 b8 1b 45 80 00 00 	movabs $0x80451b,%rax
  803619:	00 00 00 
  80361c:	ff d0                	callq  *%rax
  80361e:	48 ba 04 70 80 00 00 	movabs $0x807004,%rdx
  803625:	00 00 00 
  803628:	89 02                	mov    %eax,(%rdx)
  80362a:	48 b8 04 70 80 00 00 	movabs $0x807004,%rax
  803631:	00 00 00 
  803634:	8b 00                	mov    (%rax),%eax
  803636:	8b 75 fc             	mov    -0x4(%rbp),%esi
  803639:	b9 07 00 00 00       	mov    $0x7,%ecx
  80363e:	48 ba 00 a0 80 00 00 	movabs $0x80a000,%rdx
  803645:	00 00 00 
  803648:	89 c7                	mov    %eax,%edi
  80364a:	48 b8 10 44 80 00 00 	movabs $0x804410,%rax
  803651:	00 00 00 
  803654:	ff d0                	callq  *%rax
  803656:	ba 00 00 00 00       	mov    $0x0,%edx
  80365b:	be 00 00 00 00       	mov    $0x0,%esi
  803660:	bf 00 00 00 00       	mov    $0x0,%edi
  803665:	48 b8 4f 43 80 00 00 	movabs $0x80434f,%rax
  80366c:	00 00 00 
  80366f:	ff d0                	callq  *%rax
  803671:	c9                   	leaveq 
  803672:	c3                   	retq   

0000000000803673 <nsipc_accept>:
  803673:	55                   	push   %rbp
  803674:	48 89 e5             	mov    %rsp,%rbp
  803677:	48 83 ec 30          	sub    $0x30,%rsp
  80367b:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80367e:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  803682:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  803686:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80368d:	00 00 00 
  803690:	8b 55 ec             	mov    -0x14(%rbp),%edx
  803693:	89 10                	mov    %edx,(%rax)
  803695:	bf 01 00 00 00       	mov    $0x1,%edi
  80369a:	48 b8 f2 35 80 00 00 	movabs $0x8035f2,%rax
  8036a1:	00 00 00 
  8036a4:	ff d0                	callq  *%rax
  8036a6:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8036a9:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8036ad:	78 3e                	js     8036ed <nsipc_accept+0x7a>
  8036af:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8036b6:	00 00 00 
  8036b9:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  8036bd:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8036c1:	8b 40 10             	mov    0x10(%rax),%eax
  8036c4:	89 c2                	mov    %eax,%edx
  8036c6:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
  8036ca:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8036ce:	48 89 ce             	mov    %rcx,%rsi
  8036d1:	48 89 c7             	mov    %rax,%rdi
  8036d4:	48 b8 1c 18 80 00 00 	movabs $0x80181c,%rax
  8036db:	00 00 00 
  8036de:	ff d0                	callq  *%rax
  8036e0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8036e4:	8b 50 10             	mov    0x10(%rax),%edx
  8036e7:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8036eb:	89 10                	mov    %edx,(%rax)
  8036ed:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8036f0:	c9                   	leaveq 
  8036f1:	c3                   	retq   

00000000008036f2 <nsipc_bind>:
  8036f2:	55                   	push   %rbp
  8036f3:	48 89 e5             	mov    %rsp,%rbp
  8036f6:	48 83 ec 10          	sub    $0x10,%rsp
  8036fa:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8036fd:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  803701:	89 55 f8             	mov    %edx,-0x8(%rbp)
  803704:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80370b:	00 00 00 
  80370e:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803711:	89 10                	mov    %edx,(%rax)
  803713:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803716:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80371a:	48 89 c6             	mov    %rax,%rsi
  80371d:	48 bf 04 a0 80 00 00 	movabs $0x80a004,%rdi
  803724:	00 00 00 
  803727:	48 b8 1c 18 80 00 00 	movabs $0x80181c,%rax
  80372e:	00 00 00 
  803731:	ff d0                	callq  *%rax
  803733:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80373a:	00 00 00 
  80373d:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803740:	89 50 14             	mov    %edx,0x14(%rax)
  803743:	bf 02 00 00 00       	mov    $0x2,%edi
  803748:	48 b8 f2 35 80 00 00 	movabs $0x8035f2,%rax
  80374f:	00 00 00 
  803752:	ff d0                	callq  *%rax
  803754:	c9                   	leaveq 
  803755:	c3                   	retq   

0000000000803756 <nsipc_shutdown>:
  803756:	55                   	push   %rbp
  803757:	48 89 e5             	mov    %rsp,%rbp
  80375a:	48 83 ec 10          	sub    $0x10,%rsp
  80375e:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803761:	89 75 f8             	mov    %esi,-0x8(%rbp)
  803764:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80376b:	00 00 00 
  80376e:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803771:	89 10                	mov    %edx,(%rax)
  803773:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80377a:	00 00 00 
  80377d:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803780:	89 50 04             	mov    %edx,0x4(%rax)
  803783:	bf 03 00 00 00       	mov    $0x3,%edi
  803788:	48 b8 f2 35 80 00 00 	movabs $0x8035f2,%rax
  80378f:	00 00 00 
  803792:	ff d0                	callq  *%rax
  803794:	c9                   	leaveq 
  803795:	c3                   	retq   

0000000000803796 <nsipc_close>:
  803796:	55                   	push   %rbp
  803797:	48 89 e5             	mov    %rsp,%rbp
  80379a:	48 83 ec 10          	sub    $0x10,%rsp
  80379e:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8037a1:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8037a8:	00 00 00 
  8037ab:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8037ae:	89 10                	mov    %edx,(%rax)
  8037b0:	bf 04 00 00 00       	mov    $0x4,%edi
  8037b5:	48 b8 f2 35 80 00 00 	movabs $0x8035f2,%rax
  8037bc:	00 00 00 
  8037bf:	ff d0                	callq  *%rax
  8037c1:	c9                   	leaveq 
  8037c2:	c3                   	retq   

00000000008037c3 <nsipc_connect>:
  8037c3:	55                   	push   %rbp
  8037c4:	48 89 e5             	mov    %rsp,%rbp
  8037c7:	48 83 ec 10          	sub    $0x10,%rsp
  8037cb:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8037ce:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8037d2:	89 55 f8             	mov    %edx,-0x8(%rbp)
  8037d5:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8037dc:	00 00 00 
  8037df:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8037e2:	89 10                	mov    %edx,(%rax)
  8037e4:	8b 55 f8             	mov    -0x8(%rbp),%edx
  8037e7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8037eb:	48 89 c6             	mov    %rax,%rsi
  8037ee:	48 bf 04 a0 80 00 00 	movabs $0x80a004,%rdi
  8037f5:	00 00 00 
  8037f8:	48 b8 1c 18 80 00 00 	movabs $0x80181c,%rax
  8037ff:	00 00 00 
  803802:	ff d0                	callq  *%rax
  803804:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80380b:	00 00 00 
  80380e:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803811:	89 50 14             	mov    %edx,0x14(%rax)
  803814:	bf 05 00 00 00       	mov    $0x5,%edi
  803819:	48 b8 f2 35 80 00 00 	movabs $0x8035f2,%rax
  803820:	00 00 00 
  803823:	ff d0                	callq  *%rax
  803825:	c9                   	leaveq 
  803826:	c3                   	retq   

0000000000803827 <nsipc_listen>:
  803827:	55                   	push   %rbp
  803828:	48 89 e5             	mov    %rsp,%rbp
  80382b:	48 83 ec 10          	sub    $0x10,%rsp
  80382f:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803832:	89 75 f8             	mov    %esi,-0x8(%rbp)
  803835:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80383c:	00 00 00 
  80383f:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803842:	89 10                	mov    %edx,(%rax)
  803844:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80384b:	00 00 00 
  80384e:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803851:	89 50 04             	mov    %edx,0x4(%rax)
  803854:	bf 06 00 00 00       	mov    $0x6,%edi
  803859:	48 b8 f2 35 80 00 00 	movabs $0x8035f2,%rax
  803860:	00 00 00 
  803863:	ff d0                	callq  *%rax
  803865:	c9                   	leaveq 
  803866:	c3                   	retq   

0000000000803867 <nsipc_recv>:
  803867:	55                   	push   %rbp
  803868:	48 89 e5             	mov    %rsp,%rbp
  80386b:	48 83 ec 30          	sub    $0x30,%rsp
  80386f:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803872:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  803876:	89 55 e8             	mov    %edx,-0x18(%rbp)
  803879:	89 4d dc             	mov    %ecx,-0x24(%rbp)
  80387c:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803883:	00 00 00 
  803886:	8b 55 ec             	mov    -0x14(%rbp),%edx
  803889:	89 10                	mov    %edx,(%rax)
  80388b:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803892:	00 00 00 
  803895:	8b 55 e8             	mov    -0x18(%rbp),%edx
  803898:	89 50 04             	mov    %edx,0x4(%rax)
  80389b:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8038a2:	00 00 00 
  8038a5:	8b 55 dc             	mov    -0x24(%rbp),%edx
  8038a8:	89 50 08             	mov    %edx,0x8(%rax)
  8038ab:	bf 07 00 00 00       	mov    $0x7,%edi
  8038b0:	48 b8 f2 35 80 00 00 	movabs $0x8035f2,%rax
  8038b7:	00 00 00 
  8038ba:	ff d0                	callq  *%rax
  8038bc:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8038bf:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8038c3:	78 69                	js     80392e <nsipc_recv+0xc7>
  8038c5:	81 7d fc 3f 06 00 00 	cmpl   $0x63f,-0x4(%rbp)
  8038cc:	7f 08                	jg     8038d6 <nsipc_recv+0x6f>
  8038ce:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8038d1:	3b 45 e8             	cmp    -0x18(%rbp),%eax
  8038d4:	7e 35                	jle    80390b <nsipc_recv+0xa4>
  8038d6:	48 b9 b1 4d 80 00 00 	movabs $0x804db1,%rcx
  8038dd:	00 00 00 
  8038e0:	48 ba c6 4d 80 00 00 	movabs $0x804dc6,%rdx
  8038e7:	00 00 00 
  8038ea:	be 62 00 00 00       	mov    $0x62,%esi
  8038ef:	48 bf db 4d 80 00 00 	movabs $0x804ddb,%rdi
  8038f6:	00 00 00 
  8038f9:	b8 00 00 00 00       	mov    $0x0,%eax
  8038fe:	49 b8 0a 07 80 00 00 	movabs $0x80070a,%r8
  803905:	00 00 00 
  803908:	41 ff d0             	callq  *%r8
  80390b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80390e:	48 63 d0             	movslq %eax,%rdx
  803911:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803915:	48 be 00 a0 80 00 00 	movabs $0x80a000,%rsi
  80391c:	00 00 00 
  80391f:	48 89 c7             	mov    %rax,%rdi
  803922:	48 b8 1c 18 80 00 00 	movabs $0x80181c,%rax
  803929:	00 00 00 
  80392c:	ff d0                	callq  *%rax
  80392e:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803931:	c9                   	leaveq 
  803932:	c3                   	retq   

0000000000803933 <nsipc_send>:
  803933:	55                   	push   %rbp
  803934:	48 89 e5             	mov    %rsp,%rbp
  803937:	48 83 ec 20          	sub    $0x20,%rsp
  80393b:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80393e:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  803942:	89 55 f8             	mov    %edx,-0x8(%rbp)
  803945:	89 4d ec             	mov    %ecx,-0x14(%rbp)
  803948:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80394f:	00 00 00 
  803952:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803955:	89 10                	mov    %edx,(%rax)
  803957:	81 7d f8 3f 06 00 00 	cmpl   $0x63f,-0x8(%rbp)
  80395e:	7e 35                	jle    803995 <nsipc_send+0x62>
  803960:	48 b9 ea 4d 80 00 00 	movabs $0x804dea,%rcx
  803967:	00 00 00 
  80396a:	48 ba c6 4d 80 00 00 	movabs $0x804dc6,%rdx
  803971:	00 00 00 
  803974:	be 6d 00 00 00       	mov    $0x6d,%esi
  803979:	48 bf db 4d 80 00 00 	movabs $0x804ddb,%rdi
  803980:	00 00 00 
  803983:	b8 00 00 00 00       	mov    $0x0,%eax
  803988:	49 b8 0a 07 80 00 00 	movabs $0x80070a,%r8
  80398f:	00 00 00 
  803992:	41 ff d0             	callq  *%r8
  803995:	8b 45 f8             	mov    -0x8(%rbp),%eax
  803998:	48 63 d0             	movslq %eax,%rdx
  80399b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80399f:	48 89 c6             	mov    %rax,%rsi
  8039a2:	48 bf 0c a0 80 00 00 	movabs $0x80a00c,%rdi
  8039a9:	00 00 00 
  8039ac:	48 b8 1c 18 80 00 00 	movabs $0x80181c,%rax
  8039b3:	00 00 00 
  8039b6:	ff d0                	callq  *%rax
  8039b8:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8039bf:	00 00 00 
  8039c2:	8b 55 f8             	mov    -0x8(%rbp),%edx
  8039c5:	89 50 04             	mov    %edx,0x4(%rax)
  8039c8:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8039cf:	00 00 00 
  8039d2:	8b 55 ec             	mov    -0x14(%rbp),%edx
  8039d5:	89 50 08             	mov    %edx,0x8(%rax)
  8039d8:	bf 08 00 00 00       	mov    $0x8,%edi
  8039dd:	48 b8 f2 35 80 00 00 	movabs $0x8035f2,%rax
  8039e4:	00 00 00 
  8039e7:	ff d0                	callq  *%rax
  8039e9:	c9                   	leaveq 
  8039ea:	c3                   	retq   

00000000008039eb <nsipc_socket>:
  8039eb:	55                   	push   %rbp
  8039ec:	48 89 e5             	mov    %rsp,%rbp
  8039ef:	48 83 ec 10          	sub    $0x10,%rsp
  8039f3:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8039f6:	89 75 f8             	mov    %esi,-0x8(%rbp)
  8039f9:	89 55 f4             	mov    %edx,-0xc(%rbp)
  8039fc:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803a03:	00 00 00 
  803a06:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803a09:	89 10                	mov    %edx,(%rax)
  803a0b:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803a12:	00 00 00 
  803a15:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803a18:	89 50 04             	mov    %edx,0x4(%rax)
  803a1b:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803a22:	00 00 00 
  803a25:	8b 55 f4             	mov    -0xc(%rbp),%edx
  803a28:	89 50 08             	mov    %edx,0x8(%rax)
  803a2b:	bf 09 00 00 00       	mov    $0x9,%edi
  803a30:	48 b8 f2 35 80 00 00 	movabs $0x8035f2,%rax
  803a37:	00 00 00 
  803a3a:	ff d0                	callq  *%rax
  803a3c:	c9                   	leaveq 
  803a3d:	c3                   	retq   

0000000000803a3e <pipe>:
  803a3e:	55                   	push   %rbp
  803a3f:	48 89 e5             	mov    %rsp,%rbp
  803a42:	53                   	push   %rbx
  803a43:	48 83 ec 38          	sub    $0x38,%rsp
  803a47:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  803a4b:	48 8d 45 d8          	lea    -0x28(%rbp),%rax
  803a4f:	48 89 c7             	mov    %rax,%rdi
  803a52:	48 b8 55 22 80 00 00 	movabs $0x802255,%rax
  803a59:	00 00 00 
  803a5c:	ff d0                	callq  *%rax
  803a5e:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803a61:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803a65:	0f 88 bf 01 00 00    	js     803c2a <pipe+0x1ec>
  803a6b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803a6f:	ba 07 04 00 00       	mov    $0x407,%edx
  803a74:	48 89 c6             	mov    %rax,%rsi
  803a77:	bf 00 00 00 00       	mov    $0x0,%edi
  803a7c:	48 b8 27 1e 80 00 00 	movabs $0x801e27,%rax
  803a83:	00 00 00 
  803a86:	ff d0                	callq  *%rax
  803a88:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803a8b:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803a8f:	0f 88 95 01 00 00    	js     803c2a <pipe+0x1ec>
  803a95:	48 8d 45 d0          	lea    -0x30(%rbp),%rax
  803a99:	48 89 c7             	mov    %rax,%rdi
  803a9c:	48 b8 55 22 80 00 00 	movabs $0x802255,%rax
  803aa3:	00 00 00 
  803aa6:	ff d0                	callq  *%rax
  803aa8:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803aab:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803aaf:	0f 88 5d 01 00 00    	js     803c12 <pipe+0x1d4>
  803ab5:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803ab9:	ba 07 04 00 00       	mov    $0x407,%edx
  803abe:	48 89 c6             	mov    %rax,%rsi
  803ac1:	bf 00 00 00 00       	mov    $0x0,%edi
  803ac6:	48 b8 27 1e 80 00 00 	movabs $0x801e27,%rax
  803acd:	00 00 00 
  803ad0:	ff d0                	callq  *%rax
  803ad2:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803ad5:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803ad9:	0f 88 33 01 00 00    	js     803c12 <pipe+0x1d4>
  803adf:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803ae3:	48 89 c7             	mov    %rax,%rdi
  803ae6:	48 b8 2a 22 80 00 00 	movabs $0x80222a,%rax
  803aed:	00 00 00 
  803af0:	ff d0                	callq  *%rax
  803af2:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  803af6:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803afa:	ba 07 04 00 00       	mov    $0x407,%edx
  803aff:	48 89 c6             	mov    %rax,%rsi
  803b02:	bf 00 00 00 00       	mov    $0x0,%edi
  803b07:	48 b8 27 1e 80 00 00 	movabs $0x801e27,%rax
  803b0e:	00 00 00 
  803b11:	ff d0                	callq  *%rax
  803b13:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803b16:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803b1a:	79 05                	jns    803b21 <pipe+0xe3>
  803b1c:	e9 d9 00 00 00       	jmpq   803bfa <pipe+0x1bc>
  803b21:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803b25:	48 89 c7             	mov    %rax,%rdi
  803b28:	48 b8 2a 22 80 00 00 	movabs $0x80222a,%rax
  803b2f:	00 00 00 
  803b32:	ff d0                	callq  *%rax
  803b34:	48 89 c2             	mov    %rax,%rdx
  803b37:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803b3b:	41 b8 07 04 00 00    	mov    $0x407,%r8d
  803b41:	48 89 d1             	mov    %rdx,%rcx
  803b44:	ba 00 00 00 00       	mov    $0x0,%edx
  803b49:	48 89 c6             	mov    %rax,%rsi
  803b4c:	bf 00 00 00 00       	mov    $0x0,%edi
  803b51:	48 b8 77 1e 80 00 00 	movabs $0x801e77,%rax
  803b58:	00 00 00 
  803b5b:	ff d0                	callq  *%rax
  803b5d:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803b60:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803b64:	79 1b                	jns    803b81 <pipe+0x143>
  803b66:	90                   	nop
  803b67:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803b6b:	48 89 c6             	mov    %rax,%rsi
  803b6e:	bf 00 00 00 00       	mov    $0x0,%edi
  803b73:	48 b8 d2 1e 80 00 00 	movabs $0x801ed2,%rax
  803b7a:	00 00 00 
  803b7d:	ff d0                	callq  *%rax
  803b7f:	eb 79                	jmp    803bfa <pipe+0x1bc>
  803b81:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803b85:	48 ba e0 60 80 00 00 	movabs $0x8060e0,%rdx
  803b8c:	00 00 00 
  803b8f:	8b 12                	mov    (%rdx),%edx
  803b91:	89 10                	mov    %edx,(%rax)
  803b93:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803b97:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%rax)
  803b9e:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803ba2:	48 ba e0 60 80 00 00 	movabs $0x8060e0,%rdx
  803ba9:	00 00 00 
  803bac:	8b 12                	mov    (%rdx),%edx
  803bae:	89 10                	mov    %edx,(%rax)
  803bb0:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803bb4:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%rax)
  803bbb:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803bbf:	48 89 c7             	mov    %rax,%rdi
  803bc2:	48 b8 07 22 80 00 00 	movabs $0x802207,%rax
  803bc9:	00 00 00 
  803bcc:	ff d0                	callq  *%rax
  803bce:	89 c2                	mov    %eax,%edx
  803bd0:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  803bd4:	89 10                	mov    %edx,(%rax)
  803bd6:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  803bda:	48 8d 58 04          	lea    0x4(%rax),%rbx
  803bde:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803be2:	48 89 c7             	mov    %rax,%rdi
  803be5:	48 b8 07 22 80 00 00 	movabs $0x802207,%rax
  803bec:	00 00 00 
  803bef:	ff d0                	callq  *%rax
  803bf1:	89 03                	mov    %eax,(%rbx)
  803bf3:	b8 00 00 00 00       	mov    $0x0,%eax
  803bf8:	eb 33                	jmp    803c2d <pipe+0x1ef>
  803bfa:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803bfe:	48 89 c6             	mov    %rax,%rsi
  803c01:	bf 00 00 00 00       	mov    $0x0,%edi
  803c06:	48 b8 d2 1e 80 00 00 	movabs $0x801ed2,%rax
  803c0d:	00 00 00 
  803c10:	ff d0                	callq  *%rax
  803c12:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803c16:	48 89 c6             	mov    %rax,%rsi
  803c19:	bf 00 00 00 00       	mov    $0x0,%edi
  803c1e:	48 b8 d2 1e 80 00 00 	movabs $0x801ed2,%rax
  803c25:	00 00 00 
  803c28:	ff d0                	callq  *%rax
  803c2a:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803c2d:	48 83 c4 38          	add    $0x38,%rsp
  803c31:	5b                   	pop    %rbx
  803c32:	5d                   	pop    %rbp
  803c33:	c3                   	retq   

0000000000803c34 <_pipeisclosed>:
  803c34:	55                   	push   %rbp
  803c35:	48 89 e5             	mov    %rsp,%rbp
  803c38:	53                   	push   %rbx
  803c39:	48 83 ec 28          	sub    $0x28,%rsp
  803c3d:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  803c41:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  803c45:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  803c4c:	00 00 00 
  803c4f:	48 8b 00             	mov    (%rax),%rax
  803c52:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  803c58:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803c5b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803c5f:	48 89 c7             	mov    %rax,%rdi
  803c62:	48 b8 8d 45 80 00 00 	movabs $0x80458d,%rax
  803c69:	00 00 00 
  803c6c:	ff d0                	callq  *%rax
  803c6e:	89 c3                	mov    %eax,%ebx
  803c70:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803c74:	48 89 c7             	mov    %rax,%rdi
  803c77:	48 b8 8d 45 80 00 00 	movabs $0x80458d,%rax
  803c7e:	00 00 00 
  803c81:	ff d0                	callq  *%rax
  803c83:	39 c3                	cmp    %eax,%ebx
  803c85:	0f 94 c0             	sete   %al
  803c88:	0f b6 c0             	movzbl %al,%eax
  803c8b:	89 45 e8             	mov    %eax,-0x18(%rbp)
  803c8e:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  803c95:	00 00 00 
  803c98:	48 8b 00             	mov    (%rax),%rax
  803c9b:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  803ca1:	89 45 e4             	mov    %eax,-0x1c(%rbp)
  803ca4:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803ca7:	3b 45 e4             	cmp    -0x1c(%rbp),%eax
  803caa:	75 05                	jne    803cb1 <_pipeisclosed+0x7d>
  803cac:	8b 45 e8             	mov    -0x18(%rbp),%eax
  803caf:	eb 4f                	jmp    803d00 <_pipeisclosed+0xcc>
  803cb1:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803cb4:	3b 45 e4             	cmp    -0x1c(%rbp),%eax
  803cb7:	74 42                	je     803cfb <_pipeisclosed+0xc7>
  803cb9:	83 7d e8 01          	cmpl   $0x1,-0x18(%rbp)
  803cbd:	75 3c                	jne    803cfb <_pipeisclosed+0xc7>
  803cbf:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  803cc6:	00 00 00 
  803cc9:	48 8b 00             	mov    (%rax),%rax
  803ccc:	8b 90 d8 00 00 00    	mov    0xd8(%rax),%edx
  803cd2:	8b 4d e8             	mov    -0x18(%rbp),%ecx
  803cd5:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803cd8:	89 c6                	mov    %eax,%esi
  803cda:	48 bf fb 4d 80 00 00 	movabs $0x804dfb,%rdi
  803ce1:	00 00 00 
  803ce4:	b8 00 00 00 00       	mov    $0x0,%eax
  803ce9:	49 b8 43 09 80 00 00 	movabs $0x800943,%r8
  803cf0:	00 00 00 
  803cf3:	41 ff d0             	callq  *%r8
  803cf6:	e9 4a ff ff ff       	jmpq   803c45 <_pipeisclosed+0x11>
  803cfb:	e9 45 ff ff ff       	jmpq   803c45 <_pipeisclosed+0x11>
  803d00:	48 83 c4 28          	add    $0x28,%rsp
  803d04:	5b                   	pop    %rbx
  803d05:	5d                   	pop    %rbp
  803d06:	c3                   	retq   

0000000000803d07 <pipeisclosed>:
  803d07:	55                   	push   %rbp
  803d08:	48 89 e5             	mov    %rsp,%rbp
  803d0b:	48 83 ec 30          	sub    $0x30,%rsp
  803d0f:	89 7d dc             	mov    %edi,-0x24(%rbp)
  803d12:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  803d16:	8b 45 dc             	mov    -0x24(%rbp),%eax
  803d19:	48 89 d6             	mov    %rdx,%rsi
  803d1c:	89 c7                	mov    %eax,%edi
  803d1e:	48 b8 ed 22 80 00 00 	movabs $0x8022ed,%rax
  803d25:	00 00 00 
  803d28:	ff d0                	callq  *%rax
  803d2a:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803d2d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803d31:	79 05                	jns    803d38 <pipeisclosed+0x31>
  803d33:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803d36:	eb 31                	jmp    803d69 <pipeisclosed+0x62>
  803d38:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  803d3c:	48 89 c7             	mov    %rax,%rdi
  803d3f:	48 b8 2a 22 80 00 00 	movabs $0x80222a,%rax
  803d46:	00 00 00 
  803d49:	ff d0                	callq  *%rax
  803d4b:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  803d4f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  803d53:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803d57:	48 89 d6             	mov    %rdx,%rsi
  803d5a:	48 89 c7             	mov    %rax,%rdi
  803d5d:	48 b8 34 3c 80 00 00 	movabs $0x803c34,%rax
  803d64:	00 00 00 
  803d67:	ff d0                	callq  *%rax
  803d69:	c9                   	leaveq 
  803d6a:	c3                   	retq   

0000000000803d6b <devpipe_read>:
  803d6b:	55                   	push   %rbp
  803d6c:	48 89 e5             	mov    %rsp,%rbp
  803d6f:	48 83 ec 40          	sub    $0x40,%rsp
  803d73:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  803d77:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  803d7b:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  803d7f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803d83:	48 89 c7             	mov    %rax,%rdi
  803d86:	48 b8 2a 22 80 00 00 	movabs $0x80222a,%rax
  803d8d:	00 00 00 
  803d90:	ff d0                	callq  *%rax
  803d92:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  803d96:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803d9a:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  803d9e:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  803da5:	00 
  803da6:	e9 92 00 00 00       	jmpq   803e3d <devpipe_read+0xd2>
  803dab:	eb 41                	jmp    803dee <devpipe_read+0x83>
  803dad:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  803db2:	74 09                	je     803dbd <devpipe_read+0x52>
  803db4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803db8:	e9 92 00 00 00       	jmpq   803e4f <devpipe_read+0xe4>
  803dbd:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803dc1:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803dc5:	48 89 d6             	mov    %rdx,%rsi
  803dc8:	48 89 c7             	mov    %rax,%rdi
  803dcb:	48 b8 34 3c 80 00 00 	movabs $0x803c34,%rax
  803dd2:	00 00 00 
  803dd5:	ff d0                	callq  *%rax
  803dd7:	85 c0                	test   %eax,%eax
  803dd9:	74 07                	je     803de2 <devpipe_read+0x77>
  803ddb:	b8 00 00 00 00       	mov    $0x0,%eax
  803de0:	eb 6d                	jmp    803e4f <devpipe_read+0xe4>
  803de2:	48 b8 e9 1d 80 00 00 	movabs $0x801de9,%rax
  803de9:	00 00 00 
  803dec:	ff d0                	callq  *%rax
  803dee:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803df2:	8b 10                	mov    (%rax),%edx
  803df4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803df8:	8b 40 04             	mov    0x4(%rax),%eax
  803dfb:	39 c2                	cmp    %eax,%edx
  803dfd:	74 ae                	je     803dad <devpipe_read+0x42>
  803dff:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803e03:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  803e07:	48 8d 0c 02          	lea    (%rdx,%rax,1),%rcx
  803e0b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803e0f:	8b 00                	mov    (%rax),%eax
  803e11:	99                   	cltd   
  803e12:	c1 ea 1b             	shr    $0x1b,%edx
  803e15:	01 d0                	add    %edx,%eax
  803e17:	83 e0 1f             	and    $0x1f,%eax
  803e1a:	29 d0                	sub    %edx,%eax
  803e1c:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803e20:	48 98                	cltq   
  803e22:	0f b6 44 02 08       	movzbl 0x8(%rdx,%rax,1),%eax
  803e27:	88 01                	mov    %al,(%rcx)
  803e29:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803e2d:	8b 00                	mov    (%rax),%eax
  803e2f:	8d 50 01             	lea    0x1(%rax),%edx
  803e32:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803e36:	89 10                	mov    %edx,(%rax)
  803e38:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  803e3d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803e41:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  803e45:	0f 82 60 ff ff ff    	jb     803dab <devpipe_read+0x40>
  803e4b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803e4f:	c9                   	leaveq 
  803e50:	c3                   	retq   

0000000000803e51 <devpipe_write>:
  803e51:	55                   	push   %rbp
  803e52:	48 89 e5             	mov    %rsp,%rbp
  803e55:	48 83 ec 40          	sub    $0x40,%rsp
  803e59:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  803e5d:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  803e61:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  803e65:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803e69:	48 89 c7             	mov    %rax,%rdi
  803e6c:	48 b8 2a 22 80 00 00 	movabs $0x80222a,%rax
  803e73:	00 00 00 
  803e76:	ff d0                	callq  *%rax
  803e78:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  803e7c:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803e80:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  803e84:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  803e8b:	00 
  803e8c:	e9 8e 00 00 00       	jmpq   803f1f <devpipe_write+0xce>
  803e91:	eb 31                	jmp    803ec4 <devpipe_write+0x73>
  803e93:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803e97:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803e9b:	48 89 d6             	mov    %rdx,%rsi
  803e9e:	48 89 c7             	mov    %rax,%rdi
  803ea1:	48 b8 34 3c 80 00 00 	movabs $0x803c34,%rax
  803ea8:	00 00 00 
  803eab:	ff d0                	callq  *%rax
  803ead:	85 c0                	test   %eax,%eax
  803eaf:	74 07                	je     803eb8 <devpipe_write+0x67>
  803eb1:	b8 00 00 00 00       	mov    $0x0,%eax
  803eb6:	eb 79                	jmp    803f31 <devpipe_write+0xe0>
  803eb8:	48 b8 e9 1d 80 00 00 	movabs $0x801de9,%rax
  803ebf:	00 00 00 
  803ec2:	ff d0                	callq  *%rax
  803ec4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803ec8:	8b 40 04             	mov    0x4(%rax),%eax
  803ecb:	48 63 d0             	movslq %eax,%rdx
  803ece:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803ed2:	8b 00                	mov    (%rax),%eax
  803ed4:	48 98                	cltq   
  803ed6:	48 83 c0 20          	add    $0x20,%rax
  803eda:	48 39 c2             	cmp    %rax,%rdx
  803edd:	73 b4                	jae    803e93 <devpipe_write+0x42>
  803edf:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803ee3:	8b 40 04             	mov    0x4(%rax),%eax
  803ee6:	99                   	cltd   
  803ee7:	c1 ea 1b             	shr    $0x1b,%edx
  803eea:	01 d0                	add    %edx,%eax
  803eec:	83 e0 1f             	and    $0x1f,%eax
  803eef:	29 d0                	sub    %edx,%eax
  803ef1:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  803ef5:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  803ef9:	48 01 ca             	add    %rcx,%rdx
  803efc:	0f b6 0a             	movzbl (%rdx),%ecx
  803eff:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803f03:	48 98                	cltq   
  803f05:	88 4c 02 08          	mov    %cl,0x8(%rdx,%rax,1)
  803f09:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803f0d:	8b 40 04             	mov    0x4(%rax),%eax
  803f10:	8d 50 01             	lea    0x1(%rax),%edx
  803f13:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803f17:	89 50 04             	mov    %edx,0x4(%rax)
  803f1a:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  803f1f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803f23:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  803f27:	0f 82 64 ff ff ff    	jb     803e91 <devpipe_write+0x40>
  803f2d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803f31:	c9                   	leaveq 
  803f32:	c3                   	retq   

0000000000803f33 <devpipe_stat>:
  803f33:	55                   	push   %rbp
  803f34:	48 89 e5             	mov    %rsp,%rbp
  803f37:	48 83 ec 20          	sub    $0x20,%rsp
  803f3b:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  803f3f:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  803f43:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  803f47:	48 89 c7             	mov    %rax,%rdi
  803f4a:	48 b8 2a 22 80 00 00 	movabs $0x80222a,%rax
  803f51:	00 00 00 
  803f54:	ff d0                	callq  *%rax
  803f56:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  803f5a:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803f5e:	48 be 0e 4e 80 00 00 	movabs $0x804e0e,%rsi
  803f65:	00 00 00 
  803f68:	48 89 c7             	mov    %rax,%rdi
  803f6b:	48 b8 f8 14 80 00 00 	movabs $0x8014f8,%rax
  803f72:	00 00 00 
  803f75:	ff d0                	callq  *%rax
  803f77:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803f7b:	8b 50 04             	mov    0x4(%rax),%edx
  803f7e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803f82:	8b 00                	mov    (%rax),%eax
  803f84:	29 c2                	sub    %eax,%edx
  803f86:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803f8a:	89 90 80 00 00 00    	mov    %edx,0x80(%rax)
  803f90:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803f94:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%rax)
  803f9b:	00 00 00 
  803f9e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803fa2:	48 b9 e0 60 80 00 00 	movabs $0x8060e0,%rcx
  803fa9:	00 00 00 
  803fac:	48 89 88 88 00 00 00 	mov    %rcx,0x88(%rax)
  803fb3:	b8 00 00 00 00       	mov    $0x0,%eax
  803fb8:	c9                   	leaveq 
  803fb9:	c3                   	retq   

0000000000803fba <devpipe_close>:
  803fba:	55                   	push   %rbp
  803fbb:	48 89 e5             	mov    %rsp,%rbp
  803fbe:	48 83 ec 10          	sub    $0x10,%rsp
  803fc2:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  803fc6:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803fca:	48 89 c6             	mov    %rax,%rsi
  803fcd:	bf 00 00 00 00       	mov    $0x0,%edi
  803fd2:	48 b8 d2 1e 80 00 00 	movabs $0x801ed2,%rax
  803fd9:	00 00 00 
  803fdc:	ff d0                	callq  *%rax
  803fde:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803fe2:	48 89 c7             	mov    %rax,%rdi
  803fe5:	48 b8 2a 22 80 00 00 	movabs $0x80222a,%rax
  803fec:	00 00 00 
  803fef:	ff d0                	callq  *%rax
  803ff1:	48 89 c6             	mov    %rax,%rsi
  803ff4:	bf 00 00 00 00       	mov    $0x0,%edi
  803ff9:	48 b8 d2 1e 80 00 00 	movabs $0x801ed2,%rax
  804000:	00 00 00 
  804003:	ff d0                	callq  *%rax
  804005:	c9                   	leaveq 
  804006:	c3                   	retq   

0000000000804007 <wait>:
  804007:	55                   	push   %rbp
  804008:	48 89 e5             	mov    %rsp,%rbp
  80400b:	48 83 ec 20          	sub    $0x20,%rsp
  80400f:	89 7d ec             	mov    %edi,-0x14(%rbp)
  804012:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  804016:	75 35                	jne    80404d <wait+0x46>
  804018:	48 b9 15 4e 80 00 00 	movabs $0x804e15,%rcx
  80401f:	00 00 00 
  804022:	48 ba 20 4e 80 00 00 	movabs $0x804e20,%rdx
  804029:	00 00 00 
  80402c:	be 0a 00 00 00       	mov    $0xa,%esi
  804031:	48 bf 35 4e 80 00 00 	movabs $0x804e35,%rdi
  804038:	00 00 00 
  80403b:	b8 00 00 00 00       	mov    $0x0,%eax
  804040:	49 b8 0a 07 80 00 00 	movabs $0x80070a,%r8
  804047:	00 00 00 
  80404a:	41 ff d0             	callq  *%r8
  80404d:	8b 45 ec             	mov    -0x14(%rbp),%eax
  804050:	25 ff 03 00 00       	and    $0x3ff,%eax
  804055:	48 98                	cltq   
  804057:	48 69 d0 68 01 00 00 	imul   $0x168,%rax,%rdx
  80405e:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  804065:	00 00 00 
  804068:	48 01 d0             	add    %rdx,%rax
  80406b:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  80406f:	eb 0c                	jmp    80407d <wait+0x76>
  804071:	48 b8 e9 1d 80 00 00 	movabs $0x801de9,%rax
  804078:	00 00 00 
  80407b:	ff d0                	callq  *%rax
  80407d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  804081:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  804087:	3b 45 ec             	cmp    -0x14(%rbp),%eax
  80408a:	75 0e                	jne    80409a <wait+0x93>
  80408c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  804090:	8b 80 d4 00 00 00    	mov    0xd4(%rax),%eax
  804096:	85 c0                	test   %eax,%eax
  804098:	75 d7                	jne    804071 <wait+0x6a>
  80409a:	c9                   	leaveq 
  80409b:	c3                   	retq   

000000000080409c <cputchar>:
  80409c:	55                   	push   %rbp
  80409d:	48 89 e5             	mov    %rsp,%rbp
  8040a0:	48 83 ec 20          	sub    $0x20,%rsp
  8040a4:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8040a7:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8040aa:	88 45 ff             	mov    %al,-0x1(%rbp)
  8040ad:	48 8d 45 ff          	lea    -0x1(%rbp),%rax
  8040b1:	be 01 00 00 00       	mov    $0x1,%esi
  8040b6:	48 89 c7             	mov    %rax,%rdi
  8040b9:	48 b8 df 1c 80 00 00 	movabs $0x801cdf,%rax
  8040c0:	00 00 00 
  8040c3:	ff d0                	callq  *%rax
  8040c5:	c9                   	leaveq 
  8040c6:	c3                   	retq   

00000000008040c7 <getchar>:
  8040c7:	55                   	push   %rbp
  8040c8:	48 89 e5             	mov    %rsp,%rbp
  8040cb:	48 83 ec 10          	sub    $0x10,%rsp
  8040cf:	48 8d 45 fb          	lea    -0x5(%rbp),%rax
  8040d3:	ba 01 00 00 00       	mov    $0x1,%edx
  8040d8:	48 89 c6             	mov    %rax,%rsi
  8040db:	bf 00 00 00 00       	mov    $0x0,%edi
  8040e0:	48 b8 1f 27 80 00 00 	movabs $0x80271f,%rax
  8040e7:	00 00 00 
  8040ea:	ff d0                	callq  *%rax
  8040ec:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8040ef:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8040f3:	79 05                	jns    8040fa <getchar+0x33>
  8040f5:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8040f8:	eb 14                	jmp    80410e <getchar+0x47>
  8040fa:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8040fe:	7f 07                	jg     804107 <getchar+0x40>
  804100:	b8 f7 ff ff ff       	mov    $0xfffffff7,%eax
  804105:	eb 07                	jmp    80410e <getchar+0x47>
  804107:	0f b6 45 fb          	movzbl -0x5(%rbp),%eax
  80410b:	0f b6 c0             	movzbl %al,%eax
  80410e:	c9                   	leaveq 
  80410f:	c3                   	retq   

0000000000804110 <iscons>:
  804110:	55                   	push   %rbp
  804111:	48 89 e5             	mov    %rsp,%rbp
  804114:	48 83 ec 20          	sub    $0x20,%rsp
  804118:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80411b:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  80411f:	8b 45 ec             	mov    -0x14(%rbp),%eax
  804122:	48 89 d6             	mov    %rdx,%rsi
  804125:	89 c7                	mov    %eax,%edi
  804127:	48 b8 ed 22 80 00 00 	movabs $0x8022ed,%rax
  80412e:	00 00 00 
  804131:	ff d0                	callq  *%rax
  804133:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804136:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80413a:	79 05                	jns    804141 <iscons+0x31>
  80413c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80413f:	eb 1a                	jmp    80415b <iscons+0x4b>
  804141:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  804145:	8b 10                	mov    (%rax),%edx
  804147:	48 b8 20 61 80 00 00 	movabs $0x806120,%rax
  80414e:	00 00 00 
  804151:	8b 00                	mov    (%rax),%eax
  804153:	39 c2                	cmp    %eax,%edx
  804155:	0f 94 c0             	sete   %al
  804158:	0f b6 c0             	movzbl %al,%eax
  80415b:	c9                   	leaveq 
  80415c:	c3                   	retq   

000000000080415d <opencons>:
  80415d:	55                   	push   %rbp
  80415e:	48 89 e5             	mov    %rsp,%rbp
  804161:	48 83 ec 10          	sub    $0x10,%rsp
  804165:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  804169:	48 89 c7             	mov    %rax,%rdi
  80416c:	48 b8 55 22 80 00 00 	movabs $0x802255,%rax
  804173:	00 00 00 
  804176:	ff d0                	callq  *%rax
  804178:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80417b:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80417f:	79 05                	jns    804186 <opencons+0x29>
  804181:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804184:	eb 5b                	jmp    8041e1 <opencons+0x84>
  804186:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80418a:	ba 07 04 00 00       	mov    $0x407,%edx
  80418f:	48 89 c6             	mov    %rax,%rsi
  804192:	bf 00 00 00 00       	mov    $0x0,%edi
  804197:	48 b8 27 1e 80 00 00 	movabs $0x801e27,%rax
  80419e:	00 00 00 
  8041a1:	ff d0                	callq  *%rax
  8041a3:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8041a6:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8041aa:	79 05                	jns    8041b1 <opencons+0x54>
  8041ac:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8041af:	eb 30                	jmp    8041e1 <opencons+0x84>
  8041b1:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8041b5:	48 ba 20 61 80 00 00 	movabs $0x806120,%rdx
  8041bc:	00 00 00 
  8041bf:	8b 12                	mov    (%rdx),%edx
  8041c1:	89 10                	mov    %edx,(%rax)
  8041c3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8041c7:	c7 40 08 02 00 00 00 	movl   $0x2,0x8(%rax)
  8041ce:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8041d2:	48 89 c7             	mov    %rax,%rdi
  8041d5:	48 b8 07 22 80 00 00 	movabs $0x802207,%rax
  8041dc:	00 00 00 
  8041df:	ff d0                	callq  *%rax
  8041e1:	c9                   	leaveq 
  8041e2:	c3                   	retq   

00000000008041e3 <devcons_read>:
  8041e3:	55                   	push   %rbp
  8041e4:	48 89 e5             	mov    %rsp,%rbp
  8041e7:	48 83 ec 30          	sub    $0x30,%rsp
  8041eb:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8041ef:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8041f3:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8041f7:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8041fc:	75 07                	jne    804205 <devcons_read+0x22>
  8041fe:	b8 00 00 00 00       	mov    $0x0,%eax
  804203:	eb 4b                	jmp    804250 <devcons_read+0x6d>
  804205:	eb 0c                	jmp    804213 <devcons_read+0x30>
  804207:	48 b8 e9 1d 80 00 00 	movabs $0x801de9,%rax
  80420e:	00 00 00 
  804211:	ff d0                	callq  *%rax
  804213:	48 b8 29 1d 80 00 00 	movabs $0x801d29,%rax
  80421a:	00 00 00 
  80421d:	ff d0                	callq  *%rax
  80421f:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804222:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  804226:	74 df                	je     804207 <devcons_read+0x24>
  804228:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80422c:	79 05                	jns    804233 <devcons_read+0x50>
  80422e:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804231:	eb 1d                	jmp    804250 <devcons_read+0x6d>
  804233:	83 7d fc 04          	cmpl   $0x4,-0x4(%rbp)
  804237:	75 07                	jne    804240 <devcons_read+0x5d>
  804239:	b8 00 00 00 00       	mov    $0x0,%eax
  80423e:	eb 10                	jmp    804250 <devcons_read+0x6d>
  804240:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804243:	89 c2                	mov    %eax,%edx
  804245:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  804249:	88 10                	mov    %dl,(%rax)
  80424b:	b8 01 00 00 00       	mov    $0x1,%eax
  804250:	c9                   	leaveq 
  804251:	c3                   	retq   

0000000000804252 <devcons_write>:
  804252:	55                   	push   %rbp
  804253:	48 89 e5             	mov    %rsp,%rbp
  804256:	48 81 ec b0 00 00 00 	sub    $0xb0,%rsp
  80425d:	48 89 bd 68 ff ff ff 	mov    %rdi,-0x98(%rbp)
  804264:	48 89 b5 60 ff ff ff 	mov    %rsi,-0xa0(%rbp)
  80426b:	48 89 95 58 ff ff ff 	mov    %rdx,-0xa8(%rbp)
  804272:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  804279:	eb 76                	jmp    8042f1 <devcons_write+0x9f>
  80427b:	48 8b 85 58 ff ff ff 	mov    -0xa8(%rbp),%rax
  804282:	89 c2                	mov    %eax,%edx
  804284:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804287:	29 c2                	sub    %eax,%edx
  804289:	89 d0                	mov    %edx,%eax
  80428b:	89 45 f8             	mov    %eax,-0x8(%rbp)
  80428e:	8b 45 f8             	mov    -0x8(%rbp),%eax
  804291:	83 f8 7f             	cmp    $0x7f,%eax
  804294:	76 07                	jbe    80429d <devcons_write+0x4b>
  804296:	c7 45 f8 7f 00 00 00 	movl   $0x7f,-0x8(%rbp)
  80429d:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8042a0:	48 63 d0             	movslq %eax,%rdx
  8042a3:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8042a6:	48 63 c8             	movslq %eax,%rcx
  8042a9:	48 8b 85 60 ff ff ff 	mov    -0xa0(%rbp),%rax
  8042b0:	48 01 c1             	add    %rax,%rcx
  8042b3:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
  8042ba:	48 89 ce             	mov    %rcx,%rsi
  8042bd:	48 89 c7             	mov    %rax,%rdi
  8042c0:	48 b8 1c 18 80 00 00 	movabs $0x80181c,%rax
  8042c7:	00 00 00 
  8042ca:	ff d0                	callq  *%rax
  8042cc:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8042cf:	48 63 d0             	movslq %eax,%rdx
  8042d2:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
  8042d9:	48 89 d6             	mov    %rdx,%rsi
  8042dc:	48 89 c7             	mov    %rax,%rdi
  8042df:	48 b8 df 1c 80 00 00 	movabs $0x801cdf,%rax
  8042e6:	00 00 00 
  8042e9:	ff d0                	callq  *%rax
  8042eb:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8042ee:	01 45 fc             	add    %eax,-0x4(%rbp)
  8042f1:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8042f4:	48 98                	cltq   
  8042f6:	48 3b 85 58 ff ff ff 	cmp    -0xa8(%rbp),%rax
  8042fd:	0f 82 78 ff ff ff    	jb     80427b <devcons_write+0x29>
  804303:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804306:	c9                   	leaveq 
  804307:	c3                   	retq   

0000000000804308 <devcons_close>:
  804308:	55                   	push   %rbp
  804309:	48 89 e5             	mov    %rsp,%rbp
  80430c:	48 83 ec 08          	sub    $0x8,%rsp
  804310:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  804314:	b8 00 00 00 00       	mov    $0x0,%eax
  804319:	c9                   	leaveq 
  80431a:	c3                   	retq   

000000000080431b <devcons_stat>:
  80431b:	55                   	push   %rbp
  80431c:	48 89 e5             	mov    %rsp,%rbp
  80431f:	48 83 ec 10          	sub    $0x10,%rsp
  804323:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  804327:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  80432b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80432f:	48 be 48 4e 80 00 00 	movabs $0x804e48,%rsi
  804336:	00 00 00 
  804339:	48 89 c7             	mov    %rax,%rdi
  80433c:	48 b8 f8 14 80 00 00 	movabs $0x8014f8,%rax
  804343:	00 00 00 
  804346:	ff d0                	callq  *%rax
  804348:	b8 00 00 00 00       	mov    $0x0,%eax
  80434d:	c9                   	leaveq 
  80434e:	c3                   	retq   

000000000080434f <ipc_recv>:
  80434f:	55                   	push   %rbp
  804350:	48 89 e5             	mov    %rsp,%rbp
  804353:	48 83 ec 30          	sub    $0x30,%rsp
  804357:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80435b:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80435f:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  804363:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  804368:	75 0e                	jne    804378 <ipc_recv+0x29>
  80436a:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  804371:	00 00 00 
  804374:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  804378:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80437c:	48 89 c7             	mov    %rax,%rdi
  80437f:	48 b8 50 20 80 00 00 	movabs $0x802050,%rax
  804386:	00 00 00 
  804389:	ff d0                	callq  *%rax
  80438b:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80438e:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  804392:	79 27                	jns    8043bb <ipc_recv+0x6c>
  804394:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  804399:	74 0a                	je     8043a5 <ipc_recv+0x56>
  80439b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80439f:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
  8043a5:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8043aa:	74 0a                	je     8043b6 <ipc_recv+0x67>
  8043ac:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8043b0:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
  8043b6:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8043b9:	eb 53                	jmp    80440e <ipc_recv+0xbf>
  8043bb:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8043c0:	74 19                	je     8043db <ipc_recv+0x8c>
  8043c2:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  8043c9:	00 00 00 
  8043cc:	48 8b 00             	mov    (%rax),%rax
  8043cf:	8b 90 0c 01 00 00    	mov    0x10c(%rax),%edx
  8043d5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8043d9:	89 10                	mov    %edx,(%rax)
  8043db:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8043e0:	74 19                	je     8043fb <ipc_recv+0xac>
  8043e2:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  8043e9:	00 00 00 
  8043ec:	48 8b 00             	mov    (%rax),%rax
  8043ef:	8b 90 10 01 00 00    	mov    0x110(%rax),%edx
  8043f5:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8043f9:	89 10                	mov    %edx,(%rax)
  8043fb:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  804402:	00 00 00 
  804405:	48 8b 00             	mov    (%rax),%rax
  804408:	8b 80 08 01 00 00    	mov    0x108(%rax),%eax
  80440e:	c9                   	leaveq 
  80440f:	c3                   	retq   

0000000000804410 <ipc_send>:
  804410:	55                   	push   %rbp
  804411:	48 89 e5             	mov    %rsp,%rbp
  804414:	48 83 ec 30          	sub    $0x30,%rsp
  804418:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80441b:	89 75 e8             	mov    %esi,-0x18(%rbp)
  80441e:	48 89 55 e0          	mov    %rdx,-0x20(%rbp)
  804422:	89 4d dc             	mov    %ecx,-0x24(%rbp)
  804425:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  80442a:	75 10                	jne    80443c <ipc_send+0x2c>
  80442c:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  804433:	00 00 00 
  804436:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  80443a:	eb 0e                	jmp    80444a <ipc_send+0x3a>
  80443c:	eb 0c                	jmp    80444a <ipc_send+0x3a>
  80443e:	48 b8 e9 1d 80 00 00 	movabs $0x801de9,%rax
  804445:	00 00 00 
  804448:	ff d0                	callq  *%rax
  80444a:	8b 75 e8             	mov    -0x18(%rbp),%esi
  80444d:	8b 4d dc             	mov    -0x24(%rbp),%ecx
  804450:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  804454:	8b 45 ec             	mov    -0x14(%rbp),%eax
  804457:	89 c7                	mov    %eax,%edi
  804459:	48 b8 fb 1f 80 00 00 	movabs $0x801ffb,%rax
  804460:	00 00 00 
  804463:	ff d0                	callq  *%rax
  804465:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804468:	83 7d fc f8          	cmpl   $0xfffffff8,-0x4(%rbp)
  80446c:	74 d0                	je     80443e <ipc_send+0x2e>
  80446e:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  804472:	79 30                	jns    8044a4 <ipc_send+0x94>
  804474:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804477:	89 c1                	mov    %eax,%ecx
  804479:	48 ba 50 4e 80 00 00 	movabs $0x804e50,%rdx
  804480:	00 00 00 
  804483:	be 44 00 00 00       	mov    $0x44,%esi
  804488:	48 bf 66 4e 80 00 00 	movabs $0x804e66,%rdi
  80448f:	00 00 00 
  804492:	b8 00 00 00 00       	mov    $0x0,%eax
  804497:	49 b8 0a 07 80 00 00 	movabs $0x80070a,%r8
  80449e:	00 00 00 
  8044a1:	41 ff d0             	callq  *%r8
  8044a4:	c9                   	leaveq 
  8044a5:	c3                   	retq   

00000000008044a6 <ipc_host_recv>:
  8044a6:	55                   	push   %rbp
  8044a7:	48 89 e5             	mov    %rsp,%rbp
  8044aa:	48 83 ec 10          	sub    $0x10,%rsp
  8044ae:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8044b2:	48 ba 78 4e 80 00 00 	movabs $0x804e78,%rdx
  8044b9:	00 00 00 
  8044bc:	be 4e 00 00 00       	mov    $0x4e,%esi
  8044c1:	48 bf 66 4e 80 00 00 	movabs $0x804e66,%rdi
  8044c8:	00 00 00 
  8044cb:	b8 00 00 00 00       	mov    $0x0,%eax
  8044d0:	48 b9 0a 07 80 00 00 	movabs $0x80070a,%rcx
  8044d7:	00 00 00 
  8044da:	ff d1                	callq  *%rcx

00000000008044dc <ipc_host_send>:
  8044dc:	55                   	push   %rbp
  8044dd:	48 89 e5             	mov    %rsp,%rbp
  8044e0:	48 83 ec 20          	sub    $0x20,%rsp
  8044e4:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8044e7:	89 75 f8             	mov    %esi,-0x8(%rbp)
  8044ea:	48 89 55 f0          	mov    %rdx,-0x10(%rbp)
  8044ee:	89 4d ec             	mov    %ecx,-0x14(%rbp)
  8044f1:	48 ba 98 4e 80 00 00 	movabs $0x804e98,%rdx
  8044f8:	00 00 00 
  8044fb:	be 67 00 00 00       	mov    $0x67,%esi
  804500:	48 bf 66 4e 80 00 00 	movabs $0x804e66,%rdi
  804507:	00 00 00 
  80450a:	b8 00 00 00 00       	mov    $0x0,%eax
  80450f:	48 b9 0a 07 80 00 00 	movabs $0x80070a,%rcx
  804516:	00 00 00 
  804519:	ff d1                	callq  *%rcx

000000000080451b <ipc_find_env>:
  80451b:	55                   	push   %rbp
  80451c:	48 89 e5             	mov    %rsp,%rbp
  80451f:	48 83 ec 14          	sub    $0x14,%rsp
  804523:	89 7d ec             	mov    %edi,-0x14(%rbp)
  804526:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  80452d:	eb 4e                	jmp    80457d <ipc_find_env+0x62>
  80452f:	48 ba 00 00 80 00 80 	movabs $0x8000800000,%rdx
  804536:	00 00 00 
  804539:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80453c:	48 98                	cltq   
  80453e:	48 69 c0 68 01 00 00 	imul   $0x168,%rax,%rax
  804545:	48 01 d0             	add    %rdx,%rax
  804548:	48 05 d0 00 00 00    	add    $0xd0,%rax
  80454e:	8b 00                	mov    (%rax),%eax
  804550:	3b 45 ec             	cmp    -0x14(%rbp),%eax
  804553:	75 24                	jne    804579 <ipc_find_env+0x5e>
  804555:	48 ba 00 00 80 00 80 	movabs $0x8000800000,%rdx
  80455c:	00 00 00 
  80455f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804562:	48 98                	cltq   
  804564:	48 69 c0 68 01 00 00 	imul   $0x168,%rax,%rax
  80456b:	48 01 d0             	add    %rdx,%rax
  80456e:	48 05 c0 00 00 00    	add    $0xc0,%rax
  804574:	8b 40 08             	mov    0x8(%rax),%eax
  804577:	eb 12                	jmp    80458b <ipc_find_env+0x70>
  804579:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  80457d:	81 7d fc ff 03 00 00 	cmpl   $0x3ff,-0x4(%rbp)
  804584:	7e a9                	jle    80452f <ipc_find_env+0x14>
  804586:	b8 00 00 00 00       	mov    $0x0,%eax
  80458b:	c9                   	leaveq 
  80458c:	c3                   	retq   

000000000080458d <pageref>:
  80458d:	55                   	push   %rbp
  80458e:	48 89 e5             	mov    %rsp,%rbp
  804591:	48 83 ec 18          	sub    $0x18,%rsp
  804595:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  804599:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80459d:	48 c1 e8 15          	shr    $0x15,%rax
  8045a1:	48 89 c2             	mov    %rax,%rdx
  8045a4:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  8045ab:	01 00 00 
  8045ae:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8045b2:	83 e0 01             	and    $0x1,%eax
  8045b5:	48 85 c0             	test   %rax,%rax
  8045b8:	75 07                	jne    8045c1 <pageref+0x34>
  8045ba:	b8 00 00 00 00       	mov    $0x0,%eax
  8045bf:	eb 53                	jmp    804614 <pageref+0x87>
  8045c1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8045c5:	48 c1 e8 0c          	shr    $0xc,%rax
  8045c9:	48 89 c2             	mov    %rax,%rdx
  8045cc:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  8045d3:	01 00 00 
  8045d6:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8045da:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8045de:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8045e2:	83 e0 01             	and    $0x1,%eax
  8045e5:	48 85 c0             	test   %rax,%rax
  8045e8:	75 07                	jne    8045f1 <pageref+0x64>
  8045ea:	b8 00 00 00 00       	mov    $0x0,%eax
  8045ef:	eb 23                	jmp    804614 <pageref+0x87>
  8045f1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8045f5:	48 c1 e8 0c          	shr    $0xc,%rax
  8045f9:	48 89 c2             	mov    %rax,%rdx
  8045fc:	48 b8 00 00 a0 00 80 	movabs $0x8000a00000,%rax
  804603:	00 00 00 
  804606:	48 c1 e2 04          	shl    $0x4,%rdx
  80460a:	48 01 d0             	add    %rdx,%rax
  80460d:	0f b7 40 08          	movzwl 0x8(%rax),%eax
  804611:	0f b7 c0             	movzwl %ax,%eax
  804614:	c9                   	leaveq 
  804615:	c3                   	retq   
