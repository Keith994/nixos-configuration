{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      init.defaultBranch = "main";

      fetch.prune = true;

      core.editor = "nvim";
    };

    ignores = [
      "*.swp"
      "*.swo"
      ".DS_Store"
    ];

    # 姓名/邮箱这种个人信息单独放在本机，
    # 不强制提交进配置仓库。
    includes = [
      {
        path = "~/.config/git/local.conf";
      }
    ];
  };
}
