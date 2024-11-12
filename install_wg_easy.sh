#!/bin/bash

# Установка Docker
echo "Устанавливаем Docker..."
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker $(whoami)

# Перезагрузка shell для применения групповых изменений
echo "Перезагрузка для применения настроек Docker..."
exec su -l $USER

# Генерация случайного пароля
PASSWORD_LENGTH=12
PASSWORD=$(openssl rand -base64 $PASSWORD_LENGTH | cut -c1-$PASSWORD_LENGTH)

# Создание bcrypt-хеша пароля
PASSWORD_HASH=$(python3 -c "import bcrypt; print(bcrypt.hashpw('$PASSWORD'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8'))")

# Получение IP-адреса сервера
SERVER_IP=$(curl -s ifconfig.me)

# Запуск WG Easy в Docker
echo "Запускаем WG Easy с конфигурацией..."
docker run --detach \
  --name wg-easy \
  --env LANG=de \
  --env WG_HOST=$SERVER_IP \
  --env PASSWORD_HASH="$PASSWORD_HASH" \
  --env PORT=51821 \
  --env WG_PORT=51820 \
  --volume ~/.wg-easy:/etc/wireguard \
  --publish 51820:51820/udp \
  --publish 51821:51821/tcp \
  --cap-add NET_ADMIN \
  --cap-add SYS_MODULE \
  --sysctl 'net.ipv4.conf.all.src_valid_mark=1' \
  --sysctl 'net.ipv4.ip_forward=1' \
  --restart unless-stopped \
  ghcr.io/wg-easy/wg-easy

# Вывод данных для пользователя
echo "Установка завершена!"
echo "Вы можете получить доступ к панели WG Easy по адресу:"
echo "wg-interface: http://$SERVER_IP:51821"
echo "Пароль администратора: $PASSWORD"
