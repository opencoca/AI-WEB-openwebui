# syntax=docker/dockerfile:1
# Initialize device type args
# use build args in the docker build commmand with --build-arg="BUILDARG=true"
ARG USE_CUDA=false
ARG USE_OLLAMA=false
# Tested with cu117 for CUDA 11 and cu121 for CUDA 12 (default)
ARG USE_CUDA_VER=cu121
# any sentence transformer model; models to use can be found at https://huggingface.co/models?library=sentence-transformers
# Leaderboard: https://huggingface.co/spaces/mteb/leaderboard 
# for better performance and multilangauge support use "intfloat/multilingual-e5-large" (~2.5GB) or "intfloat/multilingual-e5-base" (~1.5GB)
# IMPORTANT: If you change the embedding model (sentence-transformers/all-MiniLM-L6-v2) and vice versa, you aren't able to use RAG Chat with your previous documents loaded in the WebUI! You need to re-embed them.
ARG USE_EMBEDDING_MODEL=intfloat/multilingual-e5-large
ARG USE_RERANKING_MODEL=""
ARG BUILD_HASH=dev-build

# The following args are used to set the user and group id for the app user
# Override at your own risk 
# non-root configurations are untested
ARG UID=0
ARG GID=0

########### System #########
#FROM --platform=$BUILDPLATFORM node:22-bookworm AS build
FROM node:22-bookworm AS build
ARG BUILD_HASH

WORKDIR /app
# Install dependencies

COPY package.json package-lock.json ./
RUN NODE_OPTIONS="--max-old-space-size=4096" npm install --loglevel verbose

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates 
    
RUN apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    pandoc \
    netcat-openbsd \
    curl \
    jq \
    gcc \
    python3 \
    python3-pip \
    python3-dev \
    ffmpeg \
    libsm6 \
    libxext6 \
    python3 && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


########### Copying files #########
COPY backend     /app/backend/
COPY cypress     /app/cypress/

COPY scripts     /app/scripts/
COPY test           /app/test/

#COPY .env  /app/.env
COPY .eslintrc.cjs /app/.eslintrc.cjs
COPY .prettierrc /app/.prettierrc

COPY cypress.config.ts /app/cypress.config.ts
COPY hatch_build.py /app/hatch_build.py
COPY i18next-parser.config.ts /app/i18next-parser.config.ts



########### WebUI backend #########
########## DEV_MODE Toggle #########
ARG DEV_MODE=false
ENV DEV_MODE=$DEV_MODE

# RUN echo "##### Set up dev server if DEV_MODE is true #####" && \
#     if [ "$DEV_MODE" = "true" ]; then \
#         echo "Setting up development mode..." && \
#         apt-get update && \
#         apt-get install -y --no-install-recommends unzip nodejs npm && \
#         npm install -g npm@latest && \
#         npm ci && \
#         NODE_OPTIONS="--max-old-space-size=4096" npm run build && \
#     else \
#         echo "Skipping development mode setup." && \
#         echo "Deleting unnecessary files..." && \
#         rm -rf src package.json package-lock.json; \
#     fi

######## Backup & Restore ########

RUN apt-get update && \
    apt-get install -y cron rclone bash-completion && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set default values for environment variables

ENV BACKUP_PATH=snapcloud-backups
ENV BACKUP_CRON="0 2 *"  
# 2 AM EST (7 AM UTC)
ENV NOTIFY_URL=https://your-webhook-url.com/notify


# Use args
ARG USE_CUDA
ARG USE_OLLAMA
ARG USE_CUDA_VER
ARG USE_EMBEDDING_MODEL
ARG USE_RERANKING_MODEL
ARG UID
ARG GID

## Basis ##
ENV ENV=prod \
    PORT=8080 \
    # pass build args to the build
    USE_OLLAMA_DOCKER=${USE_OLLAMA} \
    USE_CUDA_DOCKER=${USE_CUDA} \
    USE_CUDA_DOCKER_VER=${USE_CUDA_VER} \
    USE_EMBEDDING_MODEL_DOCKER=${USE_EMBEDDING_MODEL} \
    USE_RERANKING_MODEL_DOCKER=${USE_RERANKING_MODEL}

## Basis URL Config ##
ENV OLLAMA_BASE_URL="/ollama" \
    OPENAI_API_BASE_URL=""

## API Key and Security Config ##
ENV OPENAI_API_KEY="" \
    WEBUI_SECRET_KEY="" \
    SCARF_NO_ANALYTICS=true \
    DO_NOT_TRACK=true \
    ANONYMIZED_TELEMETRY=false

#### Other models #########################################################
## whisper TTS model settings ##
ENV WHISPER_MODEL="base" \
    WHISPER_MODEL_DIR="/app/backend/data/cache/whisper/models"

## RAG Embedding model settings ##
ENV RAG_EMBEDDING_MODEL="$USE_EMBEDDING_MODEL_DOCKER" \
    RAG_RERANKING_MODEL="$USE_RERANKING_MODEL_DOCKER" \
    SENTENCE_TRANSFORMERS_HOME="/app/backend/data/cache/embedding/models"

## Hugging Face download cache ##
ENV HF_HOME="/app/backend/data/cache/embedding/models"

## Torch Extensions ##
# ENV TORCH_EXTENSIONS_DIR="/.cache/torch_extensions"

#### Other models ##########################################################

WORKDIR /app/backend

ENV HOME=/root
# Create user and group if not root
RUN if [ $UID -ne 0 ]; then \
    if [ $GID -ne 0 ]; then \
    addgroup --gid $GID app; \
    fi; \
    adduser --uid $UID --gid $GID --home $HOME --disabled-password --no-create-home app; \
    fi

RUN mkdir -p $HOME/.cache/chroma
RUN echo -n 00000000-0000-0000-0000-000000000000 > $HOME/.cache/chroma/telemetry_user_id

# Make sure the user has access to the app and root directory
RUN chown -R $UID:$GID /app $HOME


# Conditional installation of Ollama
RUN if [ "$USE_OLLAMA" = "true" ]; then \
        curl -fsSL https://ollama.com/install.sh | sh; \
    fi

RUN pip3 install --no-cache-dir --upgrade pip --break-system-packages

#COPY --chown=$UID:$GID ./backend/requirements.txt ./requirements.txt

RUN pip3 install uv --break-system-packages

RUN TORCH_URL="https://download.pytorch.org/whl/cpu"; \
    if [ "$USE_CUDA" = "true" ]; then \
        TORCH_URL="https://download.pytorch.org/whl/$USE_CUDA_DOCKER_VER"; \
    fi && \
    pip3 install torch torchvision torchaudio --index-url $TORCH_URL --no-cache-dir --break-system-packages && \
    uv pip install --system -r requirements.txt --no-cache-dir --break-system-packages

RUN python -c "import os; from sentence_transformers import SentenceTransformer; from faster_whisper import WhisperModel; \
    SentenceTransformer(os.environ['RAG_EMBEDDING_MODEL'], device='cpu'); \
    WhisperModel(os.environ['WHISPER_MODEL'], device='cpu', compute_type='int8', download_root=os.environ['WHISPER_MODEL_DIR'])"

RUN chown -R $UID:$GID /app/backend/data/

########### WebUI frontend ##############################################################
# ENV APP_BUILD_HASH=${BUILD_HASH}




COPY postcss.config.js /app/postcss.config.js
COPY pyproject.toml /app/pyproject.toml

COPY svelte.config.js /app/svelte.config.js
COPY tailwind.config.js /app/tailwind.config.js

COPY tsconfig.json /app/tsconfig.json
COPY vite.config.ts /app/vite.config.ts

WORKDIR /app
# Install dependencies


COPY src /app/src
RUN NODE_OPTIONS="--max-old-space-size=4096" npm run build 
#########################################################################################


WORKDIR /app/backend

# copy embedding weight from build
# RUN mkdir -p /root/.cache/chroma/onnx_models/all-MiniLM-L6-v2
# COPY --from=build /app/onnx /root/.cache/chroma/onnx_models/all-MiniLM-L6-v2/onnx

# copy built frontend files
# COPY --chown=$UID:$GID --from=build /app/build /app/build
# COPY --chown=$UID:$GID --from=build /app/CHANGELOG.md /app/CHANGELOG.md
# COPY --chown=$UID:$GID --from=build /app/package.json /app/package.json

# copy backend files
COPY --chown=$UID:$GID ./backend .

EXPOSE 8080

HEALTHCHECK CMD curl --silent --fail http://localhost:${PORT:-8080}/health | jq -ne 'input.status == true' || exit 1

USER $UID:$GID

ARG BUILD_HASH
ENV WEBUI_BUILD_VERSION=${BUILD_HASH}
ENV DOCKER=true

COPY CHANGELOG.md /app/CHANGELOG.md

CMD [ "bash", "restore_backup_start.sh", "server" ] \
    # To enable dev mode: \
    # 1. Set DEV_MODE=true during docker build: --build-arg DEV_MODE=true \
    # 2. Run: docker run -it --rm <image_name> npm run dev
