# zig-kernel-ioctl (`/dev/zigcalc`)

Módulo carregável do Kernel Linux (`zigcalc.ko`) desenvolvido em **Zig 0.16.0** com camada mínima de integração em C, disponibilizando operações matemáticas em espaço de kernel via dispositivo de caractere `/dev/zigcalc` e chamada `ioctl(2)`.

## Preparação do ambiente (Alpine Linux)

    su -c "apk update && apk add build-base make kmod strace git linux-virt-dev"

## Compilação

    make

## Carregamento e Execução

    su -c "insmod kernel/zigcalc.ko"
    ./zigcalc soma 10 20
    ./zigcalc sub 50 15
    ./zigcalc mult 7 8
    ./zigcalc div 100 4
    ./zigcalc div 10 0

## Testes Automatizados e Descarregamento

    su -c "./tests/test.sh"
    su -c "rmmod zigcalc"
