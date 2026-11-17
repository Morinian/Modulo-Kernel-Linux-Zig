#ifndef ZIGCALC_IOCTL_H
#define ZIGCALC_IOCTL_H

#ifdef __KERNEL__
#include <linux/ioctl.h>
#include <linux/types.h>
#else
#include <sys/ioctl.h>
#include <stdint.h>
#endif

struct zigcalc_req {
    int32_t a;
    int32_t b;
    int32_t resultado;
};

#define ZIGCALC_MAGIC 'Z'

#define ZIGCALC_IOC_SOMA _IOWR(ZIGCALC_MAGIC, 1, struct zigcalc_req)
#define ZIGCALC_IOC_SUB  _IOWR(ZIGCALC_MAGIC, 2, struct zigcalc_req)
#define ZIGCALC_IOC_MULT _IOWR(ZIGCALC_MAGIC, 3, struct zigcalc_req)
#define ZIGCALC_IOC_DIV  _IOWR(ZIGCALC_MAGIC, 4, struct zigcalc_req)

#endif /* ZIGCALC_IOCTL_H */
