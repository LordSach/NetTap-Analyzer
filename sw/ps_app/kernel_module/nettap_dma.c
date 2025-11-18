#include <linux/module.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/interrupt.h>


static int __init nettap_dma_init(void)
{
pr_info("NetTap DMA kernel module loaded\n");
return 0;
}


static void __exit nettap_dma_exit(void)
{
pr_info("NetTap DMA kernel module unloaded\n");
}


module_init(nettap_dma_init);
module_exit(nettap_dma_exit);


MODULE_LICENSE("MIT");
