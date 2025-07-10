import { Controller, Get, Post } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Post('health')
  checkHealth(): object {
    return {
      message : 'Health check endpoint is working',
      statusCode : 200,
      success : true,
    };
  }

  @Get()
  getHello(): string {
    console.log('Hello from AppController!');
    return this.appService.getHello();
  }

  @Get('health')
  getHealth(): object {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      version: process.version,
    };
  }
}
