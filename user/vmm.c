#include <inc/lib.h>
#include <inc/vmx.h>
#include <inc/elf.h>
#include <inc/ept.h>
#include <inc/stdio.h>

#define GUEST_KERN "/vmm/kernel"
#define GUEST_BOOT "/vmm/boot"

#define JOS_ENTRY 0x7000

// Map a region of file fd into the guest at guest physical address gpa.
// The file region to map should start at fileoffset and be length filesz.
// The region to map in the guest should be memsz.  The region can span multiple pages.
//
// Return 0 on success, <0 on failure.
//
// Hint: Call sys_ept_map() for mapping page.
static int
map_in_guest(envid_t guest, uintptr_t gpa, size_t memsz,
			 int fd, size_t filesz, off_t fileoffset)
{
	/* Your code here */
	int index = 0;
	int statusFlag = -1;

	//Round down to the nearest multiple of PGSIZE starting at guest's phy addr
	if (PGOFF(gpa) != 0)
		ROUNDDOWN(gpa, PGSIZE);

	for (index = 0; index < memsz; index += PGSIZE)
	{
		if (index < filesz)
		{
			/* alloc a page in the env,temp map to use, permission flags as arg 3
			PTE_P- is present check */
			statusFlag = sys_page_alloc(thisenv->env_id, UTEMP, PTE_P | PTE_U | PTE_W);

			if (statusFlag < 0)
				return statusFlag;

			// from offset loc, move page by page, index increments by pagesize
			statusFlag = seek(fd, fileoffset + index);
			if (statusFlag < 0)
				return statusFlag;

			// read opened file
			statusFlag = readn(fd, UTEMP, MIN(PGSIZE, filesz - index));
			if (statusFlag < 0)
				return statusFlag;

			// page to be mapped for guest
			statusFlag = sys_ept_map(thisenv->env_id, (void *)UTEMP, guest, (void *)(gpa + index), __EPTE_FULL);
			if (statusFlag < 0){
				cprintf("Page map failure (If block): %e", statusFlag);
				panic("Page map failure - If block");
			}
			// Unmap - not req anymore
			sys_page_unmap(thisenv->env_id, UTEMP);
		}

		else
		{
			statusFlag = sys_page_alloc(thisenv->env_id, (void *)UTEMP, __EPTE_FULL);
			if (statusFlag < 0)
				return statusFlag;

			statusFlag = sys_ept_map(thisenv->env_id, UTEMP, guest, (void *)(gpa + index), __EPTE_FULL);

			if (statusFlag < 0){
				cprintf("Page map failure (else block): %e", statusFlag);
				panic("Page map failure - else block");
			}
			//unmap
			sys_page_unmap(thisenv->env_id, UTEMP);
		}
	}
	return 0; // success
}

// Read the ELF headers of kernel file specified by fname,
// mapping all valid segments into guest physical memory as appropriate.
//
// Return 0 on success, <0 on error
//
// Hint: compare with ELF parsing in env.c, and use map_in_guest for each segment.
static int
copy_guest_kern_gpa(envid_t guest, char *fname)
{
	/* Your code here */

	int fileDesc = -1; 		//to be able to read
	int mapStatus = -1;		
	char fileData[1024];	//how much to read into buffer	
	struct Elf *fileHeader;	//binary validation using this struct to be done
	size_t totalRead = 0;	//to error check, binary validation

	// open file in readonly mode
	fileDesc = open(fname, O_RDONLY);

	//error opening file
	if (fileDesc < 0)
		return -E_NOT_FOUND;

	//if opened, read into buffer
	totalRead = readn(fileDesc, fileData, sizeof(fileData));

	if (totalRead != sizeof(fileData))
	{ // mismatch in size
		close(fileDesc);
		return -E_NOT_FOUND; // ret -12
	}

	fileHeader = (struct Elf *)fileData;

	/*recall his header typically starts with a sequence of four unique bytes that are 0x7F followed by 0x45,
	0x4c, and 0x46 which on ASCII translation yields the three letters E, L, and F. 
	ELF_MAGIC = 0x464C457FU : read LSB to MSB */

	if (fileHeader->e_magic != ELF_MAGIC)
	{
		close(fileDesc);
		return -E_NOT_EXEC; // not a suitable binary ELF was not found in header
	}

	struct Proghdr *prgHdr = (struct Proghdr *)(fileData + fileHeader->e_phoff); //add offset to data and move tp prgHdr 
	struct Proghdr *endPrgHdr = prgHdr + fileHeader->e_phnum; // add more to prghdr, 32 bit offset
	
	//prgHdr is already initialized
	for (; prgHdr < endPrgHdr; prgHdr++)
	{
		/*The ELF header gets allocated by means of the macros defined in elf.h file. The constant
		*ELF PROG LOAD is carrying the value 1. This is actually the value for p type field of the
		*Proghdr structure. The value of 1 in particular means that the segment type is PT LOAD
		*/

		if (prgHdr->p_type == ELF_PROG_LOAD)
		{
			mapStatus = map_in_guest(guest, prgHdr->p_pa,
									 prgHdr->p_memsz, fileDesc,
									prgHdr->p_filesz, prgHdr->p_offset);
		if (mapStatus < 0)
			{
				close(fileDesc);
				return -E_NO_SYS; //Unimplemented
			}
		}
	}
	close(fileDesc);	//closure upon successful read
	return mapStatus;
}

void umain(int argc, char **argv)
{
	int ret;
	envid_t guest;
	char filename_buffer[50]; // buffer to save the path
	int vmdisk_number;
	int r;
	if ((ret = sys_env_mkguest(GUEST_MEM_SZ, JOS_ENTRY)) < 0)
	{
		cprintf("Error creating a guest OS env: %e\n", ret);
		exit();
	}
	guest = ret;

	// Copy the guest kernel code into guest phys mem.
	if ((ret = copy_guest_kern_gpa(guest, GUEST_KERN)) < 0)
	{
		cprintf("Error copying page into the guest - %d\n.", ret);
		exit();
	}

	// Now copy the bootloader.
	int fd;
	if ((fd = open(GUEST_BOOT, O_RDONLY)) < 0)
	{
		cprintf("open %s for read: %e\n", GUEST_BOOT, fd);
		exit();
	}

	// sizeof(bootloader) < 512.
	if ((ret = map_in_guest(guest, JOS_ENTRY, 512, fd, 512, 0)) < 0)
	{
		cprintf("Error mapping bootloader into the guest - %d\n.", ret);
		exit();
	}
#ifndef VMM_GUEST
	sys_vmx_incr_vmdisk_number(); // increase the vmdisk number
	// create a new guest disk image

	vmdisk_number = sys_vmx_get_vmdisk_number();
	snprintf(filename_buffer, 50, "/vmm/fs%d.img", vmdisk_number);

	cprintf("Creating a new virtual HDD at /vmm/fs%d.img\n", vmdisk_number);
	r = copy("vmm/clean-fs.img", filename_buffer);

	if (r < 0)
	{
		cprintf("Create new virtual HDD failed: %e\n", r);
		exit();
	}

	cprintf("Create VHD finished\n");
#endif
	// Mark the guest as runnable.
	sys_env_set_status(guest, ENV_RUNNABLE);
	wait(guest);
}
