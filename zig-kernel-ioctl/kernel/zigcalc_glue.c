#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/uaccess.h>
#include "zigcalc_ioctl.h"

#define DEVICE_NAME "zigcalc"
#define CLASS_NAME  "zigcalc_cls"

extern long zig_processar_ioctl(unsigned int cmd, struct zigcalc_req *req);

static dev_t dev_num;
static struct cdev zigcalc_cdev;
static struct class *zigcalc_class;

static int zigcalc_open(struct inode *inode, struct file *file)
{
    return 0;
}

static int zigcalc_release(struct inode *inode, struct file *file)
{
    return 0;
}

static long zigcalc_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
    struct zigcalc_req req;
    long ret;

    if (_IOC_TYPE(cmd) != ZIGCALC_MAGIC)
        return -ENOTTY;

    if (copy_from_user(&req, (void __user *)arg, sizeof(req)))
        return -EFAULT;

    ret = zig_processar_ioctl(cmd, &req);
    if (ret < 0)
        return ret;

    if (copy_to_user((void __user *)arg, &req, sizeof(req)))
        return -EFAULT;

    return 0;
}

static const struct file_operations zigcalc_fops = {
    .owner          = THIS_MODULE,
    .open           = zigcalc_open,
    .release        = zigcalc_release,
    .unlocked_ioctl = zigcalc_ioctl,
};

static int __init zigcalc_init(void)
{
    int ret;

    ret = alloc_chrdev_region(&dev_num, 0, 1, DEVICE_NAME);
    if (ret < 0) {
        pr_err("zigcalc: falha ao alocar major/minor (%d)\n", ret);
        return ret;
    }

    cdev_init(&zigcalc_cdev, &zigcalc_fops);
    zigcalc_cdev.owner = THIS_MODULE;

    ret = cdev_add(&zigcalc_cdev, dev_num, 1);
    if (ret < 0) {
        unregister_chrdev_region(dev_num, 1);
        pr_err("zigcalc: falha ao adicionar cdev (%d)\n", ret);
        return ret;
    }

    zigcalc_class = class_create(CLASS_NAME);
    if (IS_ERR(zigcalc_class)) {
        cdev_del(&zigcalc_cdev);
        unregister_chrdev_region(dev_num, 1);
        pr_err("zigcalc: falha ao criar classe de dispositivo\n");
        return PTR_ERR(zigcalc_class);
    }

    if (IS_ERR(device_create(zigcalc_class, NULL, dev_num, NULL, DEVICE_NAME))) {
        class_destroy(zigcalc_class);
        cdev_del(&zigcalc_cdev);
        unregister_chrdev_region(dev_num, 1);
        pr_err("zigcalc: falha ao criar /dev/%s\n", DEVICE_NAME);
        return -ENOMEM;
    }

    pr_info("zigcalc: modulo carregado (major=%d, minor=%d)\n",
            MAJOR(dev_num), MINOR(dev_num));
    return 0;
}

static void __exit zigcalc_exit(void)
{
    device_destroy(zigcalc_class, dev_num);
    class_destroy(zigcalc_class);
    cdev_del(&zigcalc_cdev);
    unregister_chrdev_region(dev_num, 1);
    pr_info("zigcalc: modulo descarregado e recursos liberados\n");
}

module_init(zigcalc_init);
module_exit(zigcalc_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Eric Donato, Matheus Henrique, Paula Martins");
MODULE_DESCRIPTION("Calculadora em espaco de kernel com Zig 0.16.0 e ioctl");
