#!/bin/sh
# unoconv-misao - REST API wrapper for unoconv
# Compatible with Moodle LMS and standard unoconv interface
# 

# Адрес поменять чтобы работало у вас
SERVER_URL="https://unoconv.misaoinst.ru"

# Парсинг аргументов в стиле unoconv
FORMAT=""
OUTPUT_FILE=""
INPUT_FILE=""

while [ $# -gt 0 ]; do
    case $1 in
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        --format=*)
            FORMAT="${1#*=}"
            shift
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --output=*)
            OUTPUT_FILE="${1#*=}"
            shift
            ;;
        -*)
            # Игнорируем остальные опции unoconv для совместимости
            shift
            ;;
        *)
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

# Проверка обязательных параметров
if [ -z "$INPUT_FILE" ]; then
    echo "unoconv: error: you have to provide an input file" >&2
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "unoconv: error: file does not exist: $INPUT_FILE" >&2
    exit 1
fi

# Определение формата по умолчанию (PDF)
if [ -z "$FORMAT" ]; then
    FORMAT="pdf"
fi

# Определение выходного файла
if [ -z "$OUTPUT_FILE" ]; then
    BASENAME=$(basename "$INPUT_FILE" | sed 's/\.[^.]*$//')
    DIRNAME=$(dirname "$INPUT_FILE")
    OUTPUT_FILE="$DIRNAME/$BASENAME.$FORMAT"
fi

# Конвертация через REST API
HTTP_CODE=$(curl -w "%{http_code}" -s \
    -X POST \
    -F "file=@$INPUT_FILE" \
    -F "convert-to=$FORMAT" \
    "$SERVER_URL/request" \
    -o "$OUTPUT_FILE" 2>/dev/null)

# Проверка результата
if [ "$HTTP_CODE" = "200" ] && [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    exit 0
else
    echo "unoconv: error: conversion failed" >&2
    [ -f "$OUTPUT_FILE" ] && rm -f "$OUTPUT_FILE"
    exit 1
fi
