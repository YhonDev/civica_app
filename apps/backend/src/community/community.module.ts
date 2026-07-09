import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [
    // TypeOrmModule.forFeature([...]) — se agregarán las entidades en S1.1
  ],
  controllers: [
    // Se agregarán en S1.5
  ],
  providers: [
    // Se agregarán en S1.3 y S1.4
  ],
  exports: [
    // Se agregarán cuando se necesiten
  ],
})
export class CommunityModule {}
