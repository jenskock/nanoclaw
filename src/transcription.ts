import { exec } from 'child_process';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { promisify } from 'util';

import { WHISPER_BIN, WHISPER_MODEL } from './config.js';
import { logger } from './logger.js';

const execAsync = promisify(exec);

export async function transcribeAudio(audioPath: string): Promise<string> {
  const tmpWav = path.join(os.tmpdir(), `nanoclaw-voice-${Date.now()}.wav`);

  try {
    // Convert to 16kHz mono WAV (required by whisper.cpp)
    await execAsync(
      `ffmpeg -i "${audioPath}" -ar 16000 -ac 1 -f wav "${tmpWav}" -y`,
    );

    // Run whisper transcription (no timestamps, plain text output)
    const { stdout } = await execAsync(
      `"${WHISPER_BIN}" -m "${WHISPER_MODEL}" -f "${tmpWav}" --no-timestamps -nt -l de`,
    );

    return stdout.trim();
  } catch (err: any) {
    logger.warn(
      { audioPath, error: err?.message ?? String(err) },
      'whisper.cpp transcription failed',
    );
    throw err;
  } finally {
    fs.unlink(tmpWav, () => {
      /* best effort */
    });
  }
}
