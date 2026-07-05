import { BadRequestException, Injectable } from "@nestjs/common";
import { randomUUID } from "crypto";
import { mkdir, writeFile } from "fs/promises";
import { extname, join } from "path";

@Injectable()
export class UploadService {
  private readonly uploadRoot = join(process.cwd(), "uploads");
  private readonly dishDir = join(this.uploadRoot, "dishes");
  private readonly avatarDir = join(this.uploadRoot, "avatars");

  async saveDishImage(file: Express.Multer.File) {
    return this.saveImage(file, this.dishDir, "dishes");
  }

  async saveAvatar(file: Express.Multer.File) {
    return this.saveImage(file, this.avatarDir, "avatars");
  }

  private async saveImage(
    file: Express.Multer.File,
    directory: string,
    scope: "dishes" | "avatars",
  ) {
    if (!["image/jpeg", "image/png", "image/webp"].includes(file.mimetype)) {
      throw new BadRequestException("只支持 jpg、jpeg、png、webp 图片");
    }
    await mkdir(directory, { recursive: true });
    const extension = this.safeExtension(file.originalname, file.mimetype);
    const filename = `${Date.now()}-${randomUUID()}${extension}`;
    await writeFile(join(directory, filename), file.buffer);
    return { url: `/uploads/${scope}/${filename}` };
  }

  private safeExtension(originalName: string, mimeType: string) {
    const raw = extname(originalName).toLowerCase();
    if ([".jpg", ".jpeg", ".png", ".webp"].includes(raw)) {
      return raw;
    }
    if (mimeType === "image/png") {
      return ".png";
    }
    if (mimeType === "image/webp") {
      return ".webp";
    }
    return ".jpg";
  }
}
