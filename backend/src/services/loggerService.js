const chalk = require('chalk');

class LoggerService {
  constructor() {
    this.icons = {
      info: 'ℹ️',
      success: '✅',
      warning: '⚠️',
      error: '❌',
      debug: '🔍',
      event: '📅',
      ai: '🤖'
    };
  }

  info(message) {
    console.log(`${this.icons.info} ${chalk.blue(message)}`);
  }

  success(message) {
    console.log(`${this.icons.success} ${chalk.green(message)}`);
  }

  warning(message) {
    console.log(`${this.icons.warning} ${chalk.yellow(message)}`);
  }

  error(message) {
    console.log(`${this.icons.error} ${chalk.red(message)}`);
  }

  debug(message) {
    console.log(`${this.icons.debug} ${chalk.gray(message)}`);
  }

  event(message) {
    console.log(`${this.icons.event} ${chalk.magenta(message)}`);
  }

  ai(message) {
    console.log(`${this.icons.ai} ${chalk.cyan(message)}`);
  }
}

module.exports = new LoggerService(); 