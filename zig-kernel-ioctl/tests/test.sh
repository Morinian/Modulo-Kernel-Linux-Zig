#!/bin/sh
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Execute como root: su -c './tests/test.sh'"
    exit 1
fi

echo "=== 1. Carregando modulo kernel/zigcalc.ko ==="
rmmod zigcalc 2>/dev/null || true
insmod kernel/zigcalc.ko

echo "=== 2. Verificando lsmod e /dev/zigcalc ==="
lsmod | grep zigcalc
sleep 0.2
ls -l /dev/zigcalc

echo "=== 3. Operacoes basicas ==="
[ "$(./zigcalc soma 10 20)" = "Resultado: 30" ] && echo "[OK] soma 10 20 -> 30"
[ "$(./zigcalc sub 50 15)" = "Resultado: 35" ] && echo "[OK] sub 50 15 -> 35"
[ "$(./zigcalc mult 7 8)" = "Resultado: 56" ] && echo "[OK] mult 7 8 -> 56"
[ "$(./zigcalc div 100 4)" = "Resultado: 25" ] && echo "[OK] div 100 4 -> 25"
[ "$(./zigcalc soma -15 5)" = "Resultado: -10" ] && echo "[OK] soma -15 5 -> -10"

echo "=== 4. Tratamento de erros (-EDOM, -ERANGE, -ENOTTY, -EFAULT) ==="
if ./zigcalc div 10 0 2>/tmp/err.txt; then
    echo "[FALHA] Divisao por zero deveria falhar"
    exit 1
fi
echo "[OK] Divisao por zero (-EDOM): $(cat /tmp/err.txt)"

if ./zigcalc soma 2147483647 1 2>/tmp/err.txt; then
    echo "[FALHA] Overflow na soma deveria falhar"
    exit 1
fi
echo "[OK] Overflow soma (-ERANGE): $(cat /tmp/err.txt)"

if ./zigcalc sub -2147483648 1 2>/tmp/err.txt; then
    echo "[FALHA] Overflow na subtracao deveria falhar"
    exit 1
fi
echo "[OK] Overflow sub (-ERANGE): $(cat /tmp/err.txt)"

if ./zigcalc mult 100000 100000 2>/tmp/err.txt; then
    echo "[FALHA] Overflow na multiplicacao deveria falhar"
    exit 1
fi
echo "[OK] Overflow mult (-ERANGE): $(cat /tmp/err.txt)"

if ./zigcalc div -2147483648 -1 2>/tmp/err.txt; then
    echo "[FALHA] Overflow minInt/-1 deveria falhar"
    exit 1
fi
echo "[OK] Overflow div minInt/-1 (-ERANGE): $(cat /tmp/err.txt)"

if ./zigcalc --test-enotty 2>/tmp/err.txt; then
    echo "[FALHA] Comando desconhecido deveria falhar"
    exit 1
fi
echo "[OK] Comando desconhecido (-ENOTTY): $(cat /tmp/err.txt)"

if ./zigcalc --test-efault 2>/tmp/err.txt; then
    echo "[FALHA] Ponteiro invalido deveria falhar"
    exit 1
fi
echo "[OK] Ponteiro invalido (-EFAULT): $(cat /tmp/err.txt)"

echo "=== 5. Execucao simultanea de 20 clientes ==="
rm -f /tmp/conc_*.out
i=1
while [ "$i" -le 20 ]; do
    ./zigcalc soma "$i" 100 > "/tmp/conc_${i}.out" &
    i=$((i + 1))
done
wait

i=1
while [ "$i" -le 20 ]; do
    esperado="Resultado: $((i + 100))"
    obtido=$(cat "/tmp/conc_${i}.out")
    if [ "$obtido" != "$esperado" ]; then
        echo "[FALHA] Concorrencia iteracao $i: esperado '$esperado', obtido '$obtido'"
        exit 1
    fi
    i=$((i + 1))
done
rm -f /tmp/conc_*.out /tmp/err.txt
echo "[OK] 20 clientes simultaneos validados sem race condition"

echo "=== 6. Descarregando modulo e verificando dmesg ==="
rmmod zigcalc
dmesg | tail -n 10
echo "=== TODOS OS TESTES CONCLUIDOS COM SUCESSO ==="
