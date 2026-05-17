import {
  BlobServiceClient,
  ContainerClient,
} from '@azure/storage-blob';
import {
  Injectable,
  InternalServerErrorException,
  Logger,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'crypto';
import { extname } from 'path';

export interface UploadedBlob {
  blobName: string;
  url: string;
}

@Injectable()
export class AzureBlobService implements OnModuleInit {
  private readonly logger = new Logger(AzureBlobService.name);
  private containerClient!: ContainerClient;

  constructor(private readonly config: ConfigService) {}

  async onModuleInit() {
    const connectionString = this.config.get<string>(
      'AZURE_STORAGE_CONNECTION_STRING',
    );
    const containerName = this.config.get<string>(
      'AZURE_STORAGE_CONTAINER',
      'product-images',
    );

    if (!connectionString) {
      throw new InternalServerErrorException(
        'AZURE_STORAGE_CONNECTION_STRING is not configured',
      );
    }

    const serviceClient =
      BlobServiceClient.fromConnectionString(connectionString);
    this.containerClient = serviceClient.getContainerClient(containerName);

    const created = await this.containerClient.createIfNotExists({
      access: 'blob',
    });
    if (created.succeeded) {
      this.logger.log(`Created blob container "${containerName}"`);
    }
  }

  async upload(file: Express.Multer.File): Promise<UploadedBlob> {
    const blobName = `${randomUUID()}${extname(file.originalname) || ''}`;
    const blockBlobClient = this.containerClient.getBlockBlobClient(blobName);

    await blockBlobClient.uploadData(file.buffer, {
      blobHTTPHeaders: { blobContentType: file.mimetype },
    });

    return { blobName, url: blockBlobClient.url };
  }

  async delete(blobName: string): Promise<void> {
    if (!blobName) return;
    await this.containerClient
      .getBlockBlobClient(blobName)
      .deleteIfExists();
  }
}
