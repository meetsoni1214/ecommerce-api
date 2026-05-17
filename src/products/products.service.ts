import { Injectable, NotFoundException } from '@nestjs/common';
import { Product } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AzureBlobService } from '../storage/azure-blob.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';

@Injectable()
export class ProductsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly blobs: AzureBlobService,
  ) {}

  async create(
    dto: CreateProductDto,
    image?: Express.Multer.File,
  ): Promise<Product> {
    const uploaded = image ? await this.blobs.upload(image) : null;
    return this.prisma.product.create({
      data: {
        name: dto.name,
        description: dto.description,
        price: dto.price,
        stock: dto.stock ?? 0,
        imageUrl: uploaded?.url ?? null,
        imageBlob: uploaded?.blobName ?? null,
      },
    });
  }

  findAll(): Promise<Product[]> {
    return this.prisma.product.findMany({ orderBy: { createdAt: 'desc' } });
  }

  async findOne(id: string): Promise<Product> {
    const product = await this.prisma.product.findUnique({ where: { id } });
    if (!product) {
      throw new NotFoundException(`Product ${id} not found`);
    }
    return product;
  }

  async update(
    id: string,
    dto: UpdateProductDto,
    image?: Express.Multer.File,
  ): Promise<Product> {
    const existing = await this.findOne(id);

    let imageUrl = existing.imageUrl;
    let imageBlob = existing.imageBlob;

    if (image) {
      if (existing.imageBlob) {
        await this.blobs.delete(existing.imageBlob);
      }
      const uploaded = await this.blobs.upload(image);
      imageUrl = uploaded.url;
      imageBlob = uploaded.blobName;
    }

    return this.prisma.product.update({
      where: { id },
      data: { ...dto, imageUrl, imageBlob },
    });
  }

  async remove(id: string): Promise<{ id: string }> {
    const existing = await this.findOne(id);
    if (existing.imageBlob) {
      await this.blobs.delete(existing.imageBlob);
    }
    await this.prisma.product.delete({ where: { id } });
    return { id };
  }
}
